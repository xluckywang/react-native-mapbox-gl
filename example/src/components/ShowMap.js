import React from 'react';
import MapboxGL from 'react-native-mapbox-gl';

import BaseExamplePropTypes from './common/BaseExamplePropTypes';
import TabBarPage from './common/TabBarPage';

import sheet from '../styles/sheet';
import colors from '../styles/colors';
import { onSortOptions } from '../utils';

class ShowMap extends React.Component {
  static propTypes = {
    ...BaseExamplePropTypes,
  };

  constructor (props) {
    super(props);

    this._mapOptions = Object.keys(MapboxGL.StyleURL).map((key) => {
      return {
        label: key,
        data: MapboxGL.StyleURL[key],
      };
    }).sort(onSortOptions);

    this.state = {
      styleURL: this._mapOptions[0].data,
    };

    this.onMapChange = this.onMapChange.bind(this);
  }

  onMapChange (index, styleURL) {
    this.setState({ styleURL: styleURL });
  }

  render () {
    return (
      <TabBarPage {...this.props} scrollable options={this._mapOptions} onOptionPress={this.onMapChange}>
        <MapboxGL.MapView
            showUserLocation={true}
            userTrackingMode={MapboxGL.UserTrackingModes.Tracking}
            styleURL={this.state.styleURL}
            style={sheet.matchParent} />
      </TabBarPage>
    );
  }
}

export default ShowMap;
