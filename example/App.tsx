import { Asset } from "expo-asset";
import * as ExpoLutFilter from "expo-lut-filter";
import { useEffect, useState } from "react";
import {
  StyleSheet,
  Text,
  View,
  Image,
  TouchableOpacity,
  ScrollView,
} from "react-native";

export default function App() {
  const [inputUri, setInputUri] = useState<null | string>(null);
  const [outputUri2, setOutputUri2] = useState<null | string>(null);

  const loadInputImage = async () => {
    const inputImage = await Asset.fromModule(
      require("./assets/inputImage2.png"),
    ).downloadAsync();
    console.log("inputImage.localUri", inputImage.localUri);
    const grain = await Asset.fromModule(
      require("./assets/grain.jpg"),
    ).downloadAsync();
    await ExpoLutFilter.setGrainImage(grain.localUri!);
    ExpoLutFilter.setGrainOpacity(0.8);
    ExpoLutFilter.setGrainBlendMode("CIScreenBlendMode");
    setInputUri(inputImage.localUri);
  };
  useEffect(() => {
    loadInputImage();
  }, []);
  const applyFilter = async () => {
    // const lut8 = await Asset.fromModule(
    //   require("./assets/LUT_8.jpg"),
    // ).downloadAsync();
    // const outputUri = await ExpoLutFilter.applyLUT(
    //   inputUri!,
    //   lut8.localUri!,
    //   64,
    // );
    // console.log("lut8.localUri", lut8.localUri);
    // console.log("outputUri 1", outputUri);
    // setOutputUri(outputUri);

    const key = "./assets/LUT_64_SaiGon.png";
    const lut64 = await Asset.fromModule(require(key)).downloadAsync();
    console.log("lut64.localUri", lut64.localUri);
    const outputUri2 = await ExpoLutFilter.applyLUT(
      inputUri!,
      key,
      lut64.localUri!,
      64,
      0.8,
      true,
    );
    console.log("outputUri 2", outputUri2);
    setOutputUri2(outputUri2);
  };
  return (
    <ScrollView contentContainerStyle={styles.container}>
      <TouchableOpacity
        style={{
          marginBottom: 20,
          backgroundColor: "#f7f7f7",
          borderRadius: 8,
          paddingHorizontal: 16,
          paddingVertical: 8,
        }}
        onPress={applyFilter}
      >
        <Text>Apply Filter</Text>
      </TouchableOpacity>
      <Text>Before:</Text>
      {inputUri ? (
        <Image
          source={{ uri: inputUri }}
          style={{ width: "100%", aspectRatio: "1/1", marginBottom: 10 }}
        />
      ) : null}
      <Text>After:</Text>
      {/* {outputUri ? (
        <Image
          key={outputUri}
          source={{ uri: outputUri ?? "" }}
          style={{ width: 200, aspectRatio: "1/1", marginBottom: 10 }}
        />
      ) : null} */}
      {outputUri2 ? (
        <Image
          key={outputUri2}
          source={{ uri: outputUri2 ?? "" }}
          style={{ width: "100%", aspectRatio: "1/1" }}
        />
      ) : null}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
    paddingTop: 200,
    // paddingBottom: 200,
  },
});
