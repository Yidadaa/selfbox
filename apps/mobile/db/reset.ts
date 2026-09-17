import { reloadAppAsync } from "expo";
import { deleteDatabaseAsync } from "expo-sqlite";

export const databaseName = "selfbox.db";

export async function resetDatabase() {
  if (!__DEV__) return;
  await deleteDatabaseAsync(databaseName);
  await reloadAppAsync();
}
