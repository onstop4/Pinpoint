import L from '../vendor/leaflet/leaflet.js';

const markerIcon = new L.Icon.Default({
    iconUrl: '../../images/leaflet/marker-icon.png',
    shadowUrl: '../../images/leaflet/marker-shadow.png'
})

export const MapHook = {
    mounted() {
        this.state = {}
        this.state.map = L.map('actual-map').setView([50, 0], 1)
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap'
        }).addTo(this.state.map)

        this.resetLocationWatcher()
        this.state.currentUserMarker = null
        this.state.friends = {}
        this.state.friendsLayerGroup = L.layerGroup([]).addTo(this.state.map)

        this.handleEvent('youve_started_sharing', () => {
            this.resetLocationWatcher()
            this.state.locationWatcher = navigator.geolocation.watchPosition(
                pos => {
                    let location = [pos.coords.latitude, pos.coords.longitude]
                    if (location[0] !== this.state.lastLocationOfCurrentUser[0] || location[1] !== this.state.lastLocationOfCurrentUser[1]) {
                        this.pushEvent('new_location', location)
                        this.state.lastLocationOfCurrentUser = location
                    }
                },
                () => pushEvent('stop_sharing_location'),
                { enableHighAccuracy: true })
        })

        this.handleEvent('youve_stopped_sharing', () => {
            this.resetLocationWatcher()
        })

        this.handleEvent('update_friends_list', payload => {
            this.state.friendsLayerGroup.clearLayers()
            this.state.friends = {}

            for (let friend_and_location of payload.friends_and_locations) {
                this.state.friends[friend_and_location.user.id] = friend_and_location.user
                this.addOrMoveFriendMarker(friend_and_location.user.id, friend_and_location.location)
            }
        })

        this.handleEvent('user_started_sharing', payload => {
            if (payload.type == 'friend') {
                this.state.friends[payload.user.id] = payload.user
                if (payload.location !== null) {
                    this.addOrMoveFriendMarker(payload.user.id, payload.location)
                }
            }
        })

        this.handleEvent('user_stopped_sharing', payload => {
            if (payload.type == 'current_user') {
                this.removeCurrentUserMarker()
            }
            else if (payload.type == 'friend') {
                this.removeFriendMarker(payload.user_id)
                delete this.state.friends[payload.user_id]
            }
        })

        this.handleEvent('user_new_location', payload => {
            if (payload.type == 'current_user') {
                this.addOrMoveCurrentUserMarker(payload.location)
            } else if (payload.type == 'friend') {
                this.addOrMoveFriendMarker(payload.user_id, payload.location)
            }
        })
    },

    disconnected() {
        this.resetLocationWatcher()
        this.removeCurrentUserMarker()
        this.state.friendsLayerGroup.clearLayers()
        this.state.friends = {}
    },

    destroyed() {
        this.resetLocationWatcher()
        if (this.state.map)
            this.state.map.remove()
    },

    resetLocationWatcher() {
        if (this.state.locationWatcher != null || this.state.locationWatcher != undefined) {
            navigator.geolocation.clearWatch(this.state.locationWatcher)
        }

        this.state.lastLocationOfCurrentUser = [null, null]
    },

    addOrMoveCurrentUserMarker(location) {
        if (this.state.currentUserMarker) {
            setLatLng(location)
        } else {
            let marker = L.marker(location, { icon: markerIcon })
            marker.bindPopup('You')
            marker.addTo(this.state.map)
            this.state.currentUserMarker = marker
        }
    },

    removeCurrentUserMarker() {
        if (this.state.currentUserMarker) {
            this.state.map.removeLayer(this.state.currentUserMarker)
            this.state.currentUserMarker = null
        }
    },

    addOrMoveFriendMarker(user_id, location) {
        let layers = this.state.friendsLayerGroup.getLayers()
        for (let layer of layers) {
            if (layer.user_id === user_id) {
                layer.setLatLng(location)
                return
            }
        }

        let user = this.state.friends[user_id]
        let marker = L.marker(location, { icon: markerIcon })
        this.state.friendsLayerGroup.addLayer(marker)
        marker._icon.classList.add('friend-marker')
        marker.user_id = user_id
        marker.bindPopup(user.name)
    },

    removeFriendMarker(user_id) {
        let layers = this.state.friendsLayerGroup.getLayers()
        for (let layer of layers) {
            if (layer.user_id === user_id) {
                this.state.friendsLayerGroup.removeLayer(layer)
                break
            }
        }
    }
}