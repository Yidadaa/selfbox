import {
  Bookmark,
  Camera,
  Coffee,
  Globe,
  Heart,
  Leaf,
  Lightbulb,
  MessageCircle,
  Moon,
  Music,
  NotebookPen,
  Star,
} from "lucide-react-native";
import { Text, View } from "react-native";
import type { ChatIcon as ChatIconValue } from "@/db/payload";
import { useAppearance } from "./appearance";

export const chatIcons = {
  message: MessageCircle,
  notebook: NotebookPen,
  lightbulb: Lightbulb,
  heart: Heart,
  star: Star,
  bookmark: Bookmark,
  coffee: Coffee,
  moon: Moon,
  leaf: Leaf,
  camera: Camera,
  music: Music,
  globe: Globe,
};

export function ChatIcon({
  icon,
  size = 52,
}: {
  icon: ChatIconValue;
  size?: number;
}) {
  const { colors } = useAppearance();
  const Icon = icon.type === "lucide" ? chatIcons[icon.name] : null;
  return (
    <View
      className="items-center justify-center"
      style={{ width: size, height: size }}
    >
      {Icon ? (
        <Icon size={size * 0.45} color={colors.accent} strokeWidth={1.7} />
      ) : icon.type === "emoji" ? (
        <Text style={{ fontSize: size * 0.5 }}>{icon.value}</Text>
      ) : null}
    </View>
  );
}
