#!/usr/bin/env python3

import argparse
import json
import sys
import time
import urllib.parse
import urllib.request
from collections import OrderedDict
from datetime import datetime, timezone


API_URL = "https://kpopping.com/api/calendar"
USER_AGENT = "discourse-kpop-dates-importer/1.0"


def parse_args():
    parser = argparse.ArgumentParser(
        description="Fetch kpopping calendar data and convert it to discourse-kpop-dates import JSON."
    )
    parser.add_argument("--start-year", type=int, required=True, help="First year to fetch")
    parser.add_argument("--end-year", type=int, required=True, help="Last year to fetch")
    parser.add_argument(
        "--months",
        default="1-12",
        help="Month selection, e.g. 1-12, 4, 4,6,9",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output JSON file path",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=0.5,
        help="Delay in seconds between requests (default: 0.5)",
    )
    return parser.parse_args()


def parse_months(raw):
    raw = raw.strip()
    if raw == "1-12":
        return list(range(1, 13))
    if "," in raw:
        return [validate_month(int(part.strip())) for part in raw.split(",") if part.strip()]
    if "-" in raw:
        start, end = raw.split("-", 1)
        start = validate_month(int(start))
        end = validate_month(int(end))
        if start > end:
            raise ValueError("month range must be ascending")
        return list(range(start, end + 1))
    return [validate_month(int(raw))]


def validate_month(value):
    if value < 1 or value > 12:
        raise ValueError(f"invalid month: {value}")
    return value


def fetch_month(year, month):
    query = urllib.parse.urlencode({"year": year, "month": month})
    url = f"{API_URL}?{query}"
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def derive_year(source_date, numeric_value):
    if numeric_value is None:
        return None
    return source_date.year - numeric_value


def normalize_slug(value):
    if not value:
        return None
    return str(value).strip().lower()


def ensure_entity(entities, warnings, slug, display_name, entity_kind):
    entity = entities.get(slug)
    if entity is None:
        entity = {
            "display_name": display_name,
            "native_name": None,
            "slug": slug,
            "entity_kind": entity_kind,
            "active": True,
            "birthday": None,
            "anniversary": None,
        }
        entities[slug] = entity
        return entity

    if entity["entity_kind"] != entity_kind:
        warnings.append(
            f"slug {slug} appeared with conflicting entity_kind values: {entity['entity_kind']} vs {entity_kind}"
        )
    if entity["display_name"] != display_name:
        warnings.append(
            f"slug {slug} appeared with conflicting display_name values: {entity['display_name']} vs {display_name}"
        )
    return entity


def merge_date_field(entity, field_name, new_value, warnings):
    if new_value is None:
        return

    current = entity[field_name]
    if current is None:
        entity[field_name] = new_value
        return

    if current != new_value:
        warnings.append(
            f"slug {entity['slug']} had conflicting {field_name} values: {current} vs {new_value}"
        )


def convert_calendar_payload(payload, entities, warnings):
    for date_string, buckets in payload.items():
        try:
            source_date = datetime.strptime(date_string, "%Y-%m-%d").date()
        except ValueError:
            warnings.append(f"skipped invalid source date: {date_string}")
            continue

        for birthday in buckets.get("birthdays", []):
            slug = normalize_slug(birthday.get("slug"))
            display_name = birthday.get("name")
            if not slug or not display_name:
                warnings.append(f"birthday row on {date_string} missing slug or name: {birthday}")
                continue

            entity = ensure_entity(entities, warnings, slug, display_name, "solo")
            birthday_value = {
                "month": source_date.month,
                "day": source_date.day,
                "year": derive_year(source_date, birthday.get("age")),
            }
            merge_date_field(entity, "birthday", birthday_value, warnings)

        for anniversary in buckets.get("anniversaries", []):
            slug = normalize_slug(anniversary.get("slug"))
            display_name = anniversary.get("group")
            if not slug or not display_name:
                warnings.append(f"anniversary row on {date_string} missing slug or group: {anniversary}")
                continue

            entity = ensure_entity(entities, warnings, slug, display_name, "group")
            anniversary_value = {
                "month": source_date.month,
                "day": source_date.day,
                "year": derive_year(source_date, anniversary.get("years")),
            }
            merge_date_field(entity, "anniversary", anniversary_value, warnings)


def build_output(entities, start_year, end_year, months, warnings):
    return {
        "source": "kpopping-calendar",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "fetched_years": {"start": start_year, "end": end_year},
        "fetched_months": months,
        "warning_count": len(warnings),
        "warnings": warnings,
        "entities": list(entities.values()),
    }


def main():
    args = parse_args()
    if args.start_year > args.end_year:
        raise SystemExit("--start-year must be <= --end-year")

    months = parse_months(args.months)
    entities = OrderedDict()
    warnings = []

    for year in range(args.start_year, args.end_year + 1):
        for month in months:
            payload = fetch_month(year, month)
            convert_calendar_payload(payload, entities, warnings)
            if args.delay > 0:
                time.sleep(args.delay)

    output = build_output(entities, args.start_year, args.end_year, months, warnings)
    with open(args.output, "w", encoding="utf-8") as handle:
        json.dump(output, handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    print(
        f"Wrote {len(output['entities'])} entities to {args.output} "
        f"(warnings={output['warning_count']})"
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Error: {error}", file=sys.stderr)
        raise SystemExit(1)
