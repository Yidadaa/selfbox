import { reloadAppAsync } from "expo";
import { deleteDatabaseAsync } from "expo-sqlite";
import { afterEach, beforeEach, expect, test, vi } from "vitest";
import { resetDatabase } from "../reset";

vi.mock("expo", () => ({ reloadAppAsync: vi.fn() }));
vi.mock("expo-sqlite", () => ({ deleteDatabaseAsync: vi.fn() }));

beforeEach(() => {
  vi.resetAllMocks();
  vi.stubGlobal("__DEV__", true);
});
afterEach(() => vi.unstubAllGlobals());

test("waits for database deletion before restarting the app", async () => {
  let finishDeletion!: () => void;
  vi.mocked(deleteDatabaseAsync).mockReturnValue(
    new Promise<void>((resolve) => {
      finishDeletion = resolve;
    }),
  );
  const resetting = resetDatabase();
  expect(deleteDatabaseAsync).toHaveBeenCalledWith("selfbox.db");
  expect(reloadAppAsync).not.toHaveBeenCalled();
  finishDeletion();
  await resetting;
  expect(reloadAppAsync).toHaveBeenCalledOnce();
});

test("propagates deletion errors without restarting", async () => {
  const error = new Error("database is still open");
  vi.mocked(deleteDatabaseAsync).mockRejectedValue(error);
  await expect(resetDatabase()).rejects.toBe(error);
  expect(reloadAppAsync).not.toHaveBeenCalled();
});

test("propagates restart errors for the error screen", async () => {
  const error = new Error("reload failed");
  vi.mocked(reloadAppAsync).mockRejectedValue(error);
  await expect(resetDatabase()).rejects.toBe(error);
});

test("does not delete or restart in production", async () => {
  vi.stubGlobal("__DEV__", false);
  await resetDatabase();
  expect(deleteDatabaseAsync).not.toHaveBeenCalled();
  expect(reloadAppAsync).not.toHaveBeenCalled();
});
