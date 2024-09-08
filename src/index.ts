import { NativeModulesProxy, EventEmitter, Subscription } from 'expo-modules-core';

// Import the native module. On web, it will be resolved to ExpoLutFilter.web.ts
// and on native platforms to ExpoLutFilter.ts
import ExpoLutFilterModule from './ExpoLutFilterModule';
import ExpoLutFilterView from './ExpoLutFilterView';
import { ChangeEventPayload, ExpoLutFilterViewProps } from './ExpoLutFilter.types';

// Get the native constant value.
export const PI = ExpoLutFilterModule.PI;

export function hello(): string {
  return ExpoLutFilterModule.hello();
}

export async function setValueAsync(value: string) {
  return await ExpoLutFilterModule.setValueAsync(value);
}

const emitter = new EventEmitter(ExpoLutFilterModule ?? NativeModulesProxy.ExpoLutFilter);

export function addChangeListener(listener: (event: ChangeEventPayload) => void): Subscription {
  return emitter.addListener<ChangeEventPayload>('onChange', listener);
}

export { ExpoLutFilterView, ExpoLutFilterViewProps, ChangeEventPayload };
