// Import the native module. On web, it will be resolved to ExpoLutFilter.web.ts
// and on native platforms to ExpoLutFilter.ts
import ExpoLutFilterModule from "./ExpoLutFilterModule";

export async function applyLUT(
  inputImageUri: string,
  filterId: string,
  lutUri: string,
  lutDimension = 8, // 8 or 16 or 64 typically
  compression?: number, // 0.0 to 1.0
) {
  return await ExpoLutFilterModule.applyLUT(
    inputImageUri,
    filterId,
    lutUri,
    lutDimension,
    compression ?? 0.8,
  );
}
