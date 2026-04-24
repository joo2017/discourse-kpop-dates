export default function () {
  this.route("kpop_dates", { path: "kpop-dates" }, function () {
    this.route("follows");

    this.route("birthdays", function () {
      this.route("today");
      this.route("tomorrow");
      this.route("upcoming");
      this.route("all");
    });

    this.route("anniversaries", function () {
      this.route("today");
      this.route("tomorrow");
      this.route("upcoming");
      this.route("all");
    });
  });
}
