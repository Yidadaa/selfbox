import { useQuery } from "@tanstack/react-query";
import { Link } from "expo-router";
import { Button } from "heroui-native/button";
import { Card } from "heroui-native/card";
import { useState } from "react";
import { ActivityIndicator, Text, View } from "react-native";
import { useBackend } from "@/components/providers";
import { ErrorMessage, Screen } from "@/components/screen";
import { messages } from "@/i18n/en";
import { useTRPC } from "@/lib/trpc";

export default function HomePage() {
  const backend = useBackend();
  const trpc = useTRPC();
  const profile = useQuery(trpc.user.me.queryOptions());
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  async function logout() {
    if (!backend || submitting) return;
    setSubmitting(true);
    setError(null);
    try {
      const result = await backend.auth.signOut();
      if (result.error) setError(messages.logoutError);
    } catch {
      setError(messages.logoutError);
    } finally {
      setSubmitting(false);
    }
  }
  return (
    <Screen>
      <Text className="text-4xl font-bold tracking-tight text-foreground">
        {messages.brand}
      </Text>
      <View className="gap-2">
        <Text className="text-3xl font-semibold text-foreground">
          {messages.homeTitle}
        </Text>
        <Text className="text-muted">{messages.homeDescription}</Text>
      </View>
      <Card className="gap-3">
        <Card.Title>{messages.profileTitle}</Card.Title>
        <Card.Description>{messages.profileDescription}</Card.Description>
        {profile.isPending && (
          <ActivityIndicator accessibilityLabel={messages.loading} />
        )}
        {profile.data && (
          <View className="gap-1">
            <Text className="text-lg font-semibold text-foreground">
              {profile.data.name}
            </Text>
            <Text selectable className="text-muted">
              {profile.data.email}
            </Text>
          </View>
        )}
        {profile.isError && (
          <>
            <ErrorMessage>{messages.profileError}</ErrorMessage>
            <Button
              variant="secondary"
              isDisabled={profile.isFetching}
              onPress={() => void profile.refetch()}
            >
              {messages.retry}
            </Button>
          </>
        )}
      </Card>
      {__DEV__ && (
        <Text selectable className="text-sm text-muted">
          {messages.server}: {backend?.baseURL}
        </Text>
      )}
      <ErrorMessage>{error}</ErrorMessage>
      <Button isDisabled={submitting} onPress={() => void logout()}>
        {submitting ? messages.submitting : messages.logout}
      </Button>
      {__DEV__ && (
        <Link href="/dev" className="text-center text-sm text-accent">
          {messages.devLink}
        </Link>
      )}
    </Screen>
  );
}
