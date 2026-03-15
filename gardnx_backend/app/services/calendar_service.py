"""Garden calendar and task generation service."""

import logging
from datetime import date, timedelta
from typing import List, Tuple

logger = logging.getLogger("gardnx")

MONTH_NAMES = [
    "", "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
]


class CalendarService:
    """Generates planting calendar events and human-readable tasks.

    Given a list of plants with their timing data, produces calendar events
    for sowing, transplanting, and harvesting, anchored to actual dates.
    """

    def generate_calendar(
        self,
        plants: list,
        start_date: date | None = None,
    ) -> list:
        """Generate calendar events for the given plant entries.

        Parameters
        ----------
        plants : list
            List of PlantCalendarEntry objects with timing info.
        start_date : date | None
            Reference date. Defaults to today.

        Returns
        -------
        list of CalendarEvent dicts
        """
        from app.api.v1.endpoints.calendar import CalendarEvent

        if start_date is None:
            start_date = date.today()

        events: list = []
        current_month = start_date.month

        for plant in plants:
            plant_name = plant.plant_name
            plant_id = plant.plant_id
            bed_name = plant.bed_name

            # --- Sowing event ---
            sow_date = self._next_date_for_months(
                start_date, plant.sowing_months, current_month
            )
            if sow_date:
                events.append(CalendarEvent(
                    plant_id=plant_id,
                    plant_name=plant_name,
                    event_type="sow",
                    start_date=sow_date.isoformat(),
                    end_date=(sow_date + timedelta(days=7)).isoformat(),
                    bed_name=bed_name,
                    description=f"Sow {plant_name} seeds in {bed_name}",
                    priority="high" if sow_date <= start_date + timedelta(days=14) else "normal",
                ))

                # --- Transplant event ---
                if plant.transplant_months:
                    transplant_date = sow_date + timedelta(days=plant.days_to_germination + 14)
                    events.append(CalendarEvent(
                        plant_id=plant_id,
                        plant_name=plant_name,
                        event_type="transplant",
                        start_date=transplant_date.isoformat(),
                        end_date=(transplant_date + timedelta(days=7)).isoformat(),
                        bed_name=bed_name,
                        description=f"Transplant {plant_name} seedlings to {bed_name}",
                        priority="normal",
                    ))

                # --- Harvest event ---
                harvest_date = sow_date + timedelta(days=plant.days_to_harvest)
                events.append(CalendarEvent(
                    plant_id=plant_id,
                    plant_name=plant_name,
                    event_type="harvest",
                    start_date=harvest_date.isoformat(),
                    end_date=(harvest_date + timedelta(days=14)).isoformat(),
                    bed_name=bed_name,
                    description=f"Expected harvest of {plant_name} from {bed_name}",
                    priority="normal",
                ))

            # --- If current month is a harvest month, add an immediate harvest note ---
            if current_month in plant.harvest_months and sow_date != start_date:
                events.append(CalendarEvent(
                    plant_id=plant_id,
                    plant_name=plant_name,
                    event_type="harvest",
                    start_date=start_date.isoformat(),
                    end_date=(start_date + timedelta(days=30)).isoformat(),
                    bed_name=bed_name,
                    description=f"Check {plant_name} in {bed_name} for harvest readiness",
                    priority="high",
                ))

        # Sort by start_date
        events.sort(key=lambda e: e.start_date)
        return events

    def generate_tasks(
        self,
        events: list,
        current_date: date | None = None,
    ) -> Tuple[List[str], List[str], List[str]]:
        """Convert calendar events into human-readable task strings.

        Parameters
        ----------
        events : list of CalendarEvent
            Calendar events to convert.
        current_date : date | None
            Reference date for relative time labels.

        Returns
        -------
        tuple of (all_tasks, urgent_tasks, upcoming_tasks)
            - all_tasks: every event as a string
            - urgent_tasks: events within the next 7 days
            - upcoming_tasks: events within the next 30 days (excluding urgent)
        """
        if current_date is None:
            current_date = date.today()

        all_tasks: List[str] = []
        urgent: List[str] = []
        upcoming: List[str] = []

        for event in events:
            event_date = date.fromisoformat(event.start_date)
            delta = (event_date - current_date).days

            task_str = self._event_to_task(event, delta)
            all_tasks.append(task_str)

            if delta <= 7:
                urgent.append(task_str)
            elif delta <= 30:
                upcoming.append(task_str)

        return all_tasks, urgent, upcoming

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _next_date_for_months(
        self,
        start_date: date,
        target_months: List[int],
        current_month: int,
    ) -> date | None:
        """Find the next occurrence of one of the target months from start_date."""
        if not target_months:
            return None

        # If current month is in the list, use start_date
        if current_month in target_months:
            return start_date

        # Find the next future month in the list
        for offset in range(1, 13):
            candidate_month = ((current_month - 1 + offset) % 12) + 1
            if candidate_month in target_months:
                # Calculate the date for this month
                year = start_date.year
                if candidate_month <= current_month:
                    year += 1
                try:
                    return date(year, candidate_month, 1)
                except ValueError:
                    return date(year, candidate_month, 1)

        return None

    def _event_to_task(self, event, days_from_now: int) -> str:
        """Convert a single event to a human-readable task string."""
        name = event.plant_name
        bed = event.bed_name
        etype = event.event_type

        if days_from_now < 0:
            time_label = f"{abs(days_from_now)} days ago"
        elif days_from_now == 0:
            time_label = "today"
        elif days_from_now == 1:
            time_label = "tomorrow"
        elif days_from_now <= 7:
            time_label = "this week"
        elif days_from_now <= 14:
            time_label = "in 2 weeks"
        elif days_from_now <= 30:
            time_label = f"in {days_from_now} days"
        elif days_from_now <= 60:
            time_label = "in about a month"
        else:
            time_label = f"in {days_from_now} days"

        if etype == "sow":
            return f"Sow {name} seeds in {bed} {time_label}"
        elif etype == "transplant":
            return f"Transplant {name} seedlings to {bed} {time_label}"
        elif etype == "harvest":
            return f"Expected harvest: {name} from {bed} {time_label}"
        elif etype == "water":
            return f"Water {name} in {bed} {time_label}"
        elif etype == "fertilize":
            return f"Fertilize {name} in {bed} {time_label}"
        else:
            return f"{etype.capitalize()} {name} in {bed} {time_label}"
