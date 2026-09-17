import { Link } from "expo-router";
import { Button } from "heroui-native/button";
import { Input } from "heroui-native/input";
import { Label } from "heroui-native/label";
import { TextField } from "heroui-native/text-field";
import { useState } from "react";
import { Text, View } from "react-native";
import { useAppearance } from "@/components/appearance";
import { useBackend } from "@/components/providers";
import { ErrorMessage, Screen } from "@/components/screen";
import type { MobileAuth } from "@/lib/auth";
import { authErrorMessage, validateCredentials } from "./validation";

function LoginForm({ auth }: { auth: MobileAuth }) {
  const { messages } = useAppearance();
  const [signup, setSignup] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    if (submitting) return;
    const validation = validateCredentials(
      email,
      password,
      signup ? confirmation : undefined,
      messages,
    );
    setError(validation);
    if (validation) return;
    setSubmitting(true);
    try {
      const credentials = { email: email.trim(), password };
      const result = signup
        ? await auth.signUp.email({
            ...credentials,
            name: credentials.email.split("@")[0] || messages.defaultUserName,
          })
        : await auth.signIn.email(credentials);
      if (result.error) setError(authErrorMessage(result.error.code, messages));
      else {
        setPassword("");
        setConfirmation("");
        await auth.getSession({ query: { disableCookieCache: true } });
      }
    } catch {
      setError(messages.networkError);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <>
      <View className="gap-2">
        <Text className="text-3xl font-semibold text-foreground">
          {signup ? messages.signupTitle : messages.loginTitle}
        </Text>
        <Text className="text-muted">
          {signup ? messages.signupDescription : messages.loginDescription}
        </Text>
      </View>
      <TextField isDisabled={submitting} isRequired>
        <Label>{messages.email}</Label>
        <Input
          accessibilityLabel={messages.email}
          placeholder={messages.emailPlaceholder}
          autoCapitalize="none"
          autoCorrect={false}
          autoComplete="email"
          keyboardType="email-address"
          value={email}
          onChangeText={setEmail}
        />
      </TextField>
      <TextField isDisabled={submitting} isRequired>
        <Label>{messages.password}</Label>
        <Input
          accessibilityLabel={messages.password}
          secureTextEntry
          autoCapitalize="none"
          autoComplete={signup ? "new-password" : "current-password"}
          value={password}
          onChangeText={setPassword}
          onSubmitEditing={() => {
            if (!signup) void submit();
          }}
        />
      </TextField>
      {signup && (
        <TextField isDisabled={submitting} isRequired>
          <Label>{messages.confirmPassword}</Label>
          <Input
            accessibilityLabel={messages.confirmPassword}
            secureTextEntry
            autoComplete="new-password"
            value={confirmation}
            onChangeText={setConfirmation}
            onSubmitEditing={() => void submit()}
          />
        </TextField>
      )}
      <ErrorMessage>{error}</ErrorMessage>
      <Button isDisabled={submitting} onPress={() => void submit()}>
        {submitting
          ? messages.submitting
          : signup
            ? messages.signup
            : messages.login}
      </Button>
      <Button
        variant="ghost"
        isDisabled={submitting}
        onPress={() => {
          setSignup(!signup);
          setError(null);
          setPassword("");
          setConfirmation("");
        }}
      >
        {signup ? messages.switchLogin : messages.switchSignup}
      </Button>
    </>
  );
}

export default function LoginPage() {
  const { messages } = useAppearance();
  const backend = useBackend();
  return (
    <Screen>
      <Text className="text-4xl font-bold tracking-tight text-foreground">
        {messages.brand}
      </Text>
      {backend ? (
        <LoginForm auth={backend.auth} />
      ) : (
        <Text className="text-muted">
          {__DEV__ ? messages.devNoHost : messages.noHost}
        </Text>
      )}
      {__DEV__ && (
        <Link href="/dev" className="text-center text-sm text-accent">
          {messages.devLink}
        </Link>
      )}
    </Screen>
  );
}
