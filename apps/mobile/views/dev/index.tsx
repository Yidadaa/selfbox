import Constants from "expo-constants";
import { router } from "expo-router";
import { Button } from "heroui-native/button";
import { Card } from "heroui-native/card";
import { Input } from "heroui-native/input";
import { Label } from "heroui-native/label";
import { TextField } from "heroui-native/text-field";
import { useRef, useState } from "react";
import { Platform, Text } from "react-native";
import { useStore } from "zustand";
import { useAppearance } from "@/components/appearance";
import { defaultHost, settingsStore, useBackend } from "@/components/providers";
import { ErrorMessage, Screen } from "@/components/screen";
import { config } from "@/env/client";
import { normalizeHost } from "@/lib/config";
import { createMobileTRPC } from "@/lib/trpc";

export default function DevPage() {
  const { messages } = useAppearance();
  const backend = useBackend();
  const devHost = useStore(settingsStore, (state) => state.devHost);
  const [host, setHost] = useState(devHost ?? backend?.baseURL ?? "");
  const [error, setError] = useState<string | null>(null);
  const [connected, setConnected] = useState(false);
  const [checking, setChecking] = useState(false);
  const checkId = useRef(0);

  function validate() {
    setError(null);
    try {
      return normalizeHost(host);
    } catch {
      setError(messages.invalidHost);
      return null;
    }
  }
  async function check() {
    const baseURL = validate();
    if (!baseURL || checking) return;
    const id = ++checkId.current;
    setChecking(true);
    setConnected(false);
    try {
      const result = await createMobileTRPC(baseURL).health.query();
      if (id === checkId.current) setConnected(result.status === "ok");
    } catch {
      if (id === checkId.current) setError(messages.networkError);
    } finally {
      if (id === checkId.current) setChecking(false);
    }
  }
  function save() {
    const baseURL = validate();
    if (!baseURL) return;
    settingsStore.getState().setDevHost(baseURL);
    router.replace("/");
  }
  return (
    <Screen>
      <Text className="text-3xl font-semibold text-foreground">
        {messages.devTitle}
      </Text>
      <Text className="text-muted">{messages.devDescription}</Text>
      <TextField>
        <Label>{messages.host}</Label>
        <Input
          accessibilityLabel={messages.host}
          placeholder={messages.hostPlaceholder}
          autoCapitalize="none"
          autoCorrect={false}
          keyboardType="url"
          value={host}
          onChangeText={(value) => {
            setHost(value);
            setConnected(false);
            setError(null);
            checkId.current++;
            setChecking(false);
          }}
        />
      </TextField>
      <Text className="text-sm text-muted">{messages.hostHint}</Text>
      <ErrorMessage>{error}</ErrorMessage>
      {connected && (
        <Text accessibilityLiveRegion="polite" className="text-success">
          {messages.connected}
        </Text>
      )}
      <Button
        variant="secondary"
        isDisabled={checking}
        onPress={() => void check()}
      >
        {checking ? messages.checking : messages.check}
      </Button>
      <Button onPress={save}>{messages.save}</Button>
      <Button
        variant="ghost"
        onPress={() => {
          settingsStore.getState().reset();
          setHost(defaultHost ?? "");
          router.replace("/");
        }}
      >
        {messages.reset}
      </Button>
      <Card className="gap-2">
        <Text selectable className="text-sm text-foreground">
          {messages.activeHost}: {backend?.baseURL ?? messages.notConfigured}
        </Text>
        <Text selectable className="text-sm text-muted">
          {messages.defaultHost}: {defaultHost ?? messages.notConfigured}
        </Text>
        <Text className="text-sm text-muted">
          {messages.configSource}:{" "}
          {messages.configSources[devHost ? "manual" : config.source]}
        </Text>
        <Text selectable className="text-sm text-muted">
          {messages.metroHost}:{" "}
          {Constants.expoConfig?.hostUri ?? messages.notConfigured}
        </Text>
        {config.devHostError && (
          <ErrorMessage>{messages.autoHostError}</ErrorMessage>
        )}
        <Text className="text-sm text-muted">
          {messages.platform}: {Platform.OS}
        </Text>
        <Text className="text-sm text-muted">
          {messages.sdk}: {Constants.expoConfig?.sdkVersion}
        </Text>
      </Card>
      <Button
        variant="ghost"
        onPress={() => {
          if (router.canGoBack()) router.back();
          else router.replace("/");
        }}
      >
        {messages.back}
      </Button>
    </Screen>
  );
}
