import initSqlJs, {
  type BindParams,
  type Database,
  type ParamsObject,
  type SqlValue,
} from "sql.js";

const SQL = await initSqlJs({
  locateFile: (file: String) => `https://sql.js.org/dist/${file}`,
});

// To be implemented on Database:
// getRowsModified
// handleError
// iterateStatements
// prepare (this constructs a statement)
//
// And for statements:
// bind
// free
// freemem
// get
// getAsObject
// getColumnNames
// getNormalizedSQL
// getSQL
// reset
// run
// step

export function create() {
  return new SQL.Database();
}

export function close(db: Database) {
  db.close();
}

export function each(
  db: Database,
  sql: string,
  params: [string, string][],
  callback: (obj: Record<string, SqlValue>) => void,
  done: () => void,
) {
  const parameters = arrayOfKeyValuePairsToBindParams(params);
  db.each(sql, parameters, callback, done);
}

function arrayOfKeyValuePairsToBindParams(
  arrayOfKeyValuePairs: [string, string][],
): BindParams {
  return arrayOfKeyValuePairs.map((pair) => pair[1]);
}

export function exec(
  db: Database,
  sql: string,
  params: [string, string][],
): initSqlJs.QueryExecResult[] {
  return db.exec(sql, arrayOfKeyValuePairsToBindParams(params));
}
export function run(
  db: Database,
  sql: string,
  params: [string, string][],
): void {
  db.run(sql, arrayOfKeyValuePairsToBindParams(params));
}
