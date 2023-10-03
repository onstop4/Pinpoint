import L from '../vendor/leaflet/leaflet.js';

const markerIcon = new L.Icon.Default({
    iconUrl: '../../images/leaflet/marker-icon.png',
    iconRetinaUrl: '../../images/leaflet/marker-icon-2x.png',
    shadowUrl: '../../images/leaflet/marker-shadow.png'
})

function notNullOrUndefined(value) {
    return value !== null && value !== undefined
}

export const MapHook = {
    mounted() {
        this.state = {}
        this.state.map = L.map('map', { zoomControl: false }).setView([50, 0], 1)
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap'
        }).addTo(this.state.map)
        L.control.zoom({
            position: 'topright'
        }).addTo(this.state.map);

        this.resetLocationWatcher()
        this.state.currentUserMarker = null
        this.state.friends = {}
        this.state.friendsMarkers = {}
        this.state.friendsLayerGroup = L.layerGroup([]).addTo(this.state.map)

        this.handleEvent('youve_started_sharing', () => {
            this.resetLocationWatcher()
            this.state.locationWatcher = navigator.geolocation.watchPosition(
                pos => {
                    let location = [pos.coords.latitude, pos.coords.longitude]
                    if (location[0] !== this.state.lastLocationOfCurrentUser[0] && location[1] !== this.state.lastLocationOfCurrentUser[1]) {
                        this.pushEvent('new_location', location)
                        this.state.lastLocationOfCurrentUser = location
                    }
                },
                () => this.pushEvent('stop_sharing_location'),
                { enableHighAccuracy: true })
        })

        this.handleEvent('youve_stopped_sharing', () => {
            this.resetLocationWatcher()
        })

        this.handleEvent('update_friends_list', payload => {
            this.removeAllFriends()

            for (let friend_and_location of payload.friends_and_locations) {
                this.state.friends[friend_and_location.user.id] = friend_and_location.user
                if (notNullOrUndefined(friend_and_location.location))
                    this.addOrMoveFriendMarker(friend_and_location.user.id, friend_and_location.location)
            }
        })

        this.handleEvent('user_started_sharing', payload => {
            if (payload.type == 'friend') {
                this.state.friends[payload.user.id] = payload.user
                if (notNullOrUndefined(payload.location)) {
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

            if (payload.go_to) {
                this.goToLocation(payload.location)
            }
        })

        this.handleEvent('go_to_user', payload => {
            if (payload.type == 'current_user') {
                if (notNullOrUndefined(this.state.currentUserMarker)) {
                    this.goToLocation(this.state.currentUserMarker.getLatLng())
                }
            } else if (payload.type == 'friend') {
                if (notNullOrUndefined(this.state.friendsMarkers[payload.user_id])) {
                    this.goToLocation(this.state.friendsMarkers[payload.user_id].getLatLng())
                }
            }
        })
    },

    disconnected() {
        this.resetLocationWatcher()
        this.removeCurrentUserMarker()
        this.removeAllFriends()
    },

    destroyed() {
        this.resetLocationWatcher()
        if (this.state.map)
            this.state.map.remove()
    },

    resetLocationWatcher() {
        if (notNullOrUndefined(this.state.locationWatcher)) {
            navigator.geolocation.clearWatch(this.state.locationWatcher)
        }

        this.state.lastLocationOfCurrentUser = [null, null]
    },

    addOrMoveCurrentUserMarker(location) {
        if (notNullOrUndefined(this.state.currentUserMarker)) {
            this.state.currentUserMarker.setLatLng(location)
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
        if (notNullOrUndefined(this.state.friendsMarkers[user_id])) {
            this.state.friendsMarkers[user_id].setLatLng(location)
        } else {
            let user = this.state.friends[user_id]
            let marker = L.marker(location, { icon: markerIcon })
            this.state.friendsLayerGroup.addLayer(marker)
            marker._icon.classList.add('friend-marker')
            marker.user_id = user_id
            marker.bindPopup(user.name)
            this.state.friendsMarkers[user_id] = marker
        }
    },

    removeFriendMarker(user_id) {
        if (notNullOrUndefined(this.state.friendsMarkers[user_id])) {
            this.state.friendsLayerGroup.removeLayer(this.state.friendsMarkers[user_id])
            this.state.friendsMarkers[user_id] = null
        }
    },

    removeAllFriends() {
        this.state.friendsLayerGroup.clearLayers()
        this.state.friends = {}
        this.state.friendsMarkers = {}
    },

    goToLocation(location) {
        this.state.map.setView(location, this.state.map.getZoom())
    }
}
