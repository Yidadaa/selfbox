import { randomUUID } from "expo-crypto";
import { openDatabaseSync } from "expo-sqlite";
import { Button } from "heroui-native/button";
import {
  createContext,
  type ReactNode,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { ActivityIndicator, Alert, ScrollView, Text } from "react-native";
import { migrateDatabase } from "@/db/migrate";
import migrations from "@/db/migrations/migrations";
import { createRepository, type Repository } from "@/db/repository";
import { databaseName, resetDatabase } from "@/db/reset";
import { pruneAttachments } from "@/lib/attachments";
import { errorText } from "@/lib/errors";
import { useAppearance } from "./appearance";
import { SafeAreaView } from "./safe-area";

const DatabaseContext = createContext<{
  repository: Repository;
  revision: number;
  refresh: () => void;
} | null>(null);
let opening: Promise<Repository> | undefined;

async function loadRepository() {
  const sqlite = openDatabaseSync(databaseName);
  try {
    const db = await migrateDatabase(sqlite, migrations);
    return createRepository(db, randomUUID);
  } catch (error) {
    try {
      sqlite.closeSync();
    } catch {
      // 关闭连接失败不能覆盖原始初始化异常。
    }
    throw error;
  }
}

function openRepository() {
  opening ??= loadRepository().catch((error) => {
    opening = undefined;
    throw error;
  });
  return opening;
}

export function DatabaseProvider({ children }: { children: ReactNode }) {
  const { colors, messages } = useAppearance();
  const [database, setDatabase] = useState<Repository>();
  const [failure, setFailure] = useState<{ details: string | null } | null>(
    null,
  );
  const [attempt, setAttempt] = useState(0);
  const [revision, setRevision] = useState(0);
  const [resetting, setResetting] = useState(false);
  const resetInProgress = useRef(false);
  async function reset() {
    if (!__DEV__ || resetInProgress.current) return;
    resetInProgress.current = true;
    setResetting(true);
    try {
      await resetDatabase();
    } catch (error) {
      console.error("[database] Reset failed", error);
      setFailure({ details: errorText(error) });
    } finally {
      resetInProgress.current = false;
      setResetting(false);
    }
  }
  useEffect(() => {
    void attempt;
    let active = true;
    void openRepository()
      .then((next) => {
        if (!active) return;
        // 删除消息后未能清理的文件会在下次启动时重试，不影响已提交的消息。
        try {
          pruneAttachments(next.imageFiles());
        } catch {
          /* 下次启动重试 */
        }
        setDatabase(next);
      })
      .catch((error: unknown) => {
        if (__DEV__) console.error("[database] Initialization failed", error);
        if (active) setFailure({ details: errorText(error) });
      });
    return () => {
      active = false;
    };
  }, [attempt]);
  const value = useMemo(
    () =>
      database
        ? {
            repository: database,
            revision,
            refresh: () => setRevision((value) => value + 1),
          }
        : null,
    [database, revision],
  );
  if (!value)
    return (
      <SafeAreaView className="flex-1 bg-background">
        <ScrollView
          contentContainerStyle={{
            flexGrow: 1,
            justifyContent: "center",
            padding: 32,
            gap: 20,
          }}
        >
          {failure ? (
            <>
              <Text
                accessibilityRole="alert"
                className="text-lg font-semibold text-foreground"
              >
                {messages.databaseError}
              </Text>
              <Text className="text-sm text-muted">
                {messages.errorDetails}
              </Text>
              <Text
                selectable
                accessibilityLabel={messages.errorDetails}
                className="rounded-2xl bg-surface p-4 text-sm text-danger"
              >
                {failure.details ?? messages.unknownError}
              </Text>
              <Button
                isDisabled={resetting}
                onPress={() => {
                  setFailure(null);
                  setAttempt((value) => value + 1);
                }}
              >
                {messages.retry}
              </Button>
              {__DEV__ && (
                <Button
                  variant="danger-soft"
                  isDisabled={resetting}
                  onPress={() => {
                    Alert.alert(
                      messages.resetDatabase,
                      messages.resetDatabaseHint,
                      [
                        { text: messages.cancel, style: "cancel" },
                        {
                          text: messages.resetDatabase,
                          style: "destructive",
                          onPress: () => void reset(),
                        },
                      ],
                    );
                  }}
                >
                  {resetting ? messages.loading : messages.resetDatabase}
                </Button>
              )}
            </>
          ) : (
            <ActivityIndicator
              color={colors.accent}
              accessibilityLabel={messages.loading}
            />
          )}
        </ScrollView>
      </SafeAreaView>
    );
  return <DatabaseContext value={value}>{children}</DatabaseContext>;
}

export function useDatabase() {
  const value = useContext(DatabaseContext);
  if (!value) throw new Error("Missing DatabaseProvider");
  return value;
}
