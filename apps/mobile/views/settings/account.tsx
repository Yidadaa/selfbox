import { router } from "expo-router";
import { Button } from "heroui-native/button";
import { ArrowLeft, UserRound } from "lucide-react-native";
import { Text, View } from "react-native";
import { useAppearance } from "@/components/appearance";
import { SafeAreaView } from "@/components/safe-area";

export default function AccountPage() {
  const { colors, messages } = useAppearance();
  return (
    <SafeAreaView className="flex-1 bg-background">
      <View
        className="flex-row items-center gap-1 border-b-border px-3 py-2"
        style={{ borderBottomWidth: 0.5 }}
      >
        <Button
          accessibilityLabel={messages.back}
          isIconOnly
          variant="ghost"
          className="h-11 w-11 rounded-full"
          onPress={() => {
            if (router.canGoBack()) router.back();
            else router.replace("/");
          }}
        >
          <ArrowLeft size={23} color={colors.text} strokeWidth={1.8} />
        </Button>
        <Text className="flex-1 px-1 text-lg font-semibold text-foreground">
          {messages.account}
        </Text>
      </View>
      <View className="items-center px-8 pt-16">
        <View className="mb-7 h-24 w-24 items-center justify-center">
          <UserRound size={45} color={colors.muted} strokeWidth={1.3} />
        </View>
        <Text className="text-3xl font-bold text-foreground">
          {messages.accountHint}
        </Text>
        <Text className="mt-4 text-center text-base text-muted">
          {messages.accountDescription}
        </Text>
        <View className="mt-10 w-full gap-3 rounded-3xl p-6 bg-surface">
          <Text className="text-base font-semibold text-foreground">
            {messages.accountComingSoon}
          </Text>
          <Text className="text-sm leading-6 text-muted">
            {messages.accountSoon}
          </Text>
        </View>
      </View>
    </SafeAreaView>
  );
}
