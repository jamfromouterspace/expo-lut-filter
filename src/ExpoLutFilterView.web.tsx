import * as React from 'react';

import { ExpoLutFilterViewProps } from './ExpoLutFilter.types';

export default function ExpoLutFilterView(props: ExpoLutFilterViewProps) {
  return (
    <div>
      <span>{props.name}</span>
    </div>
  );
}
