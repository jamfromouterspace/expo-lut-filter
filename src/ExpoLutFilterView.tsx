import { requireNativeViewManager } from 'expo-modules-core';
import * as React from 'react';

import { ExpoLutFilterViewProps } from './ExpoLutFilter.types';

const NativeView: React.ComponentType<ExpoLutFilterViewProps> =
  requireNativeViewManager('ExpoLutFilter');

export default function ExpoLutFilterView(props: ExpoLutFilterViewProps) {
  return <NativeView {...props} />;
}
