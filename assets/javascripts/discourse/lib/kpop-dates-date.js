import { inNDays, now } from "discourse/lib/time-utils";
import { i18n } from "discourse-i18n";

const KST_TIMEZONE = "Asia/Seoul";

export function kstMoment(offsetDays = 0) {
  return offsetDays === 0 ? now(KST_TIMEZONE) : inNDays(KST_TIMEZONE, offsetDays);
}

export function formattedKstDate(offsetDays = 0) {
  return kstMoment(offsetDays).format(i18n("dates.full_no_year_no_time"));
}
