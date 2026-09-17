import { ImageOff } from "lucide-react-native";
import { useState } from "react";
import { Image, Text, View } from "react-native";
import { useAppearance } from "@/components/appearance";
import type { ImageAttachment } from "@/db/payload";
import { attachmentUri } from "@/lib/attachments";
import { imageRows } from "./layout";

function Photo({
  image,
  width,
  height,
  label,
  color,
}: {
  image: ImageAttachment;
  width: number;
  height: number;
  label: string;
  color: string;
}) {
  const { messages } = useAppearance();
  const [failed, setFailed] = useState(false);
  return failed ? (
    <View
      accessibilityLabel={`${label}: ${messages.imageUnavailable}`}
      className="items-center justify-center gap-2 p-2"
      style={{ width, height }}
    >
      <ImageOff color={color} size={24} />
      {width >= 140 && (
        <Text className="text-center text-xs" style={{ color }}>
          {messages.imageUnavailable}
        </Text>
      )}
    </View>
  ) : (
    <Image
      accessibilityLabel={label}
      source={{ uri: attachmentUri(image) }}
      onError={() => setFailed(true)}
      style={{ width, height }}
      resizeMode="cover"
    />
  );
}

export function MessageImages({
  images,
  width,
  color,
}: {
  images: ImageAttachment[];
  width: number;
  color: string;
}) {
  const { messages } = useAppearance();
  const rows = imageRows(images);
  let offset = 0;
  return (
    <View className="overflow-hidden rounded-[17px]" style={{ width, gap: 3 }}>
      {rows.map((row) => {
        const start = offset;
        offset += row.length;
        const tileWidth = (width - (row.length - 1) * 3) / row.length;
        return (
          <View key={start} className="flex-row" style={{ gap: 3 }}>
            {row.map((image, index) => (
              <Photo
                key={image.file}
                image={image}
                width={tileWidth}
                height={
                  images.length === 1
                    ? Math.min(
                        340,
                        Math.max(110, (width * image.height) / image.width),
                      )
                    : row.length === 1
                      ? width * 0.62
                      : tileWidth
                }
                label={`${messages.image} ${start + index + 1}/${images.length}`}
                color={color}
              />
            ))}
          </View>
        );
      })}
    </View>
  );
}
