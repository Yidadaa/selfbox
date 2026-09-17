import { BlurView, type BlurViewProps } from "expo-blur";
import { StyleSheet, View, type ViewProps } from "react-native";
import { useAppearance } from "@/components/appearance";

export function Glass({
  blurTarget,
  children,
  className,
  ...props
}: ViewProps & { blurTarget: BlurViewProps["blurTarget"] }) {
  const { dark } = useAppearance();

  return (
    <View {...props} className={`overflow-hidden ${className ?? ""}`}>
      <BlurView
        pointerEvents="none"
        blurTarget={blurTarget}
        blurMethod="dimezisBlurViewSdk31Plus"
        intensity={70}
        tint={dark ? "systemThinMaterialDark" : "systemThinMaterialLight"}
        style={StyleSheet.absoluteFill}
      />
      {children}
    </View>
  );
}
