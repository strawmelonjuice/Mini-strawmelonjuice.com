import moment, { type Moment } from "moment";

export function parse(datestr: string) {
  return moment(datestr, false).toDate();
}

export function create(timestamp: Date) {
  return timestamp.toISOString();
}

// export function to_minutes_since_epoch(timestamp: Moment): number {
//   return timestamp.unix() / 60;
// }
//
// export function from_minutes_since_epoch(minutes: number): Moment {
//   return moment.unix(minutes * 60);
// }
