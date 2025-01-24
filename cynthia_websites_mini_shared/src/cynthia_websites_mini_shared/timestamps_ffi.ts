import moment, { type Moment } from "moment";

export function parse(datestr: string) {
  return moment(datestr, false);
}

export function create(timestamp: Moment) {
  return timestamp.toISOString(true);
}

export function to_minutes_since_epoch(timestamp: Moment): number {
  return timestamp.unix() / 60;
}

export function from_minutes_since_epoch(minutes: number): Moment {
  return moment.unix(minutes * 60);
}

export function rn(): Moment {
  return moment();
}
