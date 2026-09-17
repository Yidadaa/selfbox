import { router } from "expo-router";
import { Search, SearchX } from "lucide-react-native";
import { useMemo, useState } from "react";
import {
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useAppearance } from "@/components/appearance";
import { useDatabase } from "@/components/database";
import { ChatIcon } from "@/components/icons";
import { SafeAreaView } from "@/components/safe-area";
import { messageText } from "@/db/payload";
import { formatDate, formatTime } from "@/i18n";

export default function ChatsPage() {
  const { colors, messages, language } = useAppearance();
  const database = useDatabase();
  const [search, setSearch] = useState("");
  const insets = useSafeAreaInsets();
  const allChats = useMemo(() => database.repository.listChats(), [database]);
  const chats = allChats.filter((chat) =>
    (chat.isDefault ? messages.monologue : chat.name)
      .toLocaleLowerCase()
      .includes(search.trim().toLocaleLowerCase()),
  );
  return (
    <SafeAreaView
      edges={["top", "left", "right"]}
      className="flex-1 bg-background"
    >
      <View className="px-6 pb-5 pt-6">
        <View className="mt-6 flex-row items-center gap-2.5 rounded-2xl px-4 bg-accent-foreground">
          <Search color={colors.muted} size={18} strokeWidth={1.8} />
          <TextInput
            accessibilityLabel={messages.searchChats}
            placeholder={messages.searchChats}
            placeholderTextColor={colors.muted}
            value={search}
            onChangeText={setSearch}
            className="h-12 flex-1 text-base text-foreground"
            returnKeyType="search"
            clearButtonMode="while-editing"
          />
        </View>
      </View>
      <FlatList
        className="flex-1"
        data={chats}
        keyExtractor={(chat) => chat.id}
        keyboardShouldPersistTaps="handled"
        keyboardDismissMode="on-drag"
        contentContainerStyle={{
          paddingHorizontal: 16,
          paddingBottom: insets.bottom + 110,
        }}
        renderItem={({ item, index }) => {
          const name = item.isDefault ? messages.monologue : item.name;
          const today =
            item.latest &&
            new Date(item.latest.createdAt).toDateString() ===
              new Date().toDateString();
          return (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={name}
              onPress={() =>
                router.push({ pathname: "/chat/[id]", params: { id: item.id } })
              }
              className="flex-row items-center gap-3.5 px-4 py-3"
              style={({ pressed }) => ({
                backgroundColor: pressed ? colors.elevated : colors.surface,
                borderTopLeftRadius: index === 0 ? 24 : 0,
                borderTopRightRadius: index === 0 ? 24 : 0,
                borderBottomLeftRadius: index === chats.length - 1 ? 24 : 0,
                borderBottomRightRadius: index === chats.length - 1 ? 24 : 0,
              })}
            >
              <ChatIcon icon={item.icon} />
              <View className="flex-1 gap-1">
                <View className="flex-row items-center">
                  <Text
                    className="flex-1 font-semibold text-foreground"
                    numberOfLines={1}
                  >
                    {name}
                  </Text>
                  {item.latest && (
                    <Text className="text-xs text-muted">
                      {today
                        ? formatTime(item.latest.createdAt, language)
                        : formatDate(item.latest.createdAt, language)}
                    </Text>
                  )}
                </View>
                <Text numberOfLines={1} className="text-sm text-muted">
                  {item.latest
                    ? messageText(item.latest.payload) || messages.image
                    : messages.emptyPreview}
                </Text>
              </View>
            </Pressable>
          );
        }}
        ItemSeparatorComponent={() => (
          <View
            style={{
              height: StyleSheet.hairlineWidth,
            }}
            className="bg-border"
          />
        )}
        ListEmptyComponent={
          <View className="items-center gap-3 py-16">
            <SearchX color={colors.muted} size={30} />
            <Text className="text-lg font-medium text-foreground">
              {messages.noSearchResults}
            </Text>
            <Text className="text-muted">{messages.searchHint}</Text>
          </View>
        }
        ListFooterComponent={
          <Text className="px-4 pt-7 text-center text-xs text-muted">
            {messages.localOnly}
          </Text>
        }
      />
    </SafeAreaView>
  );
}
