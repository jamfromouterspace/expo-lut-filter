// Import the native module. On web, it will be resolved to ExpoLutFilter.web.ts
// and on native platforms to ExpoLutFilter.ts
import ExpoLutFilterModule from "./ExpoLutFilterModule";

export async function applyLUT(
  inputImageUri: string,
  lutUri: string,
  lutDimension = 8, // 8 or 16 or 64 typically
) {
  return await ExpoLutFilterModule.applyLUT(
    inputImageUri,
    lutUri,
    lutDimension,
  );
}
