import initSqlJs, {
  type BindParams,
  type Database,
  type ParamsObject,
  type SqlValue,
} from "sql.js";
//@ts-expect-error
import * as Gleam from "../gleam.mjs";

export function get_specific_item_from_global_config(
  key: string,
  db: Database,
) {
  let val;
  try {
    const res = db.exec("SELECT $value FROM globalConfig", { $value: key });
    val = res[0].values[0][0]?.toString();
  } catch (e) {
    return new Gleam.Error(null);
  }
  if (val === undefined) {
    return new Gleam.Error(null);
  } else {
    return new Gleam.Ok(val);
  }
}
