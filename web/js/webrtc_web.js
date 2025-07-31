// Web-native WebRTC implementation for Flutter web
class WebRTCWeb {
    constructor() {
        this.localStream = null;
        this.remoteStream = null;
        this.peerConnection = null;
        this.isInCall = false;
        this.isMuted = false;
        this.isVideoOn = false;
        this.onRemoteStreamCallback = null;
        this.onLocalStreamCallback = null;
        this.onCallConnectedCallback = null;
        this.onCallEndedCallback = null;
        this.onErrorCallback = null;
        
        // STUN servers for NAT traversal
        this.configuration = {
            iceServers: [
                { urls: 'stun:stun.l.google.com:19302' },
                { urls: 'stun:stun1.l.google.com:19302' }
            ]
        };
        
        console.log('🚀 WebRTCWeb initialized');
    }
    
    // Set callback functions
    setCallbacks(callbacks) {
        this.onRemoteStreamCallback = callbacks.onRemoteStream;
        this.onLocalStreamCallback = callbacks.onLocalStream;
        this.onCallConnectedCallback = callbacks.onCallConnected;
        this.onCallEndedCallback = callbacks.onCallEnded;
        this.onErrorCallback = callbacks.onError;
    }
    
    // Get user media (camera/microphone)
    async getUserMedia(audioOnly = true) {
        try {
            const constraints = {
                audio: true,
                video: !audioOnly
            };
            
            this.localStream = await navigator.mediaDevices.getUserMedia(constraints);
            console.log('✅ Got user media:', constraints);
            
            if (this.onLocalStreamCallback) {
                this.onLocalStreamCallback(this.localStream);
            }
            
            return this.localStream;
        } catch (error) {
            console.error('❌ Failed to get user media:', error);
            if (this.onErrorCallback) {
                this.onErrorCallback(`Failed to access camera/microphone: ${error.message}`);
            }
            throw error;
        }
    }
    
    // Create peer connection
    createPeerConnection() {
        try {
            this.peerConnection = new RTCPeerConnection(this.configuration);
            
            // Handle ICE candidates
            this.peerConnection.onicecandidate = (event) => {
                if (event.candidate) {
                    console.log('📡 ICE Candidate:', event.candidate);
                    // Send ICE candidate through Flutter callback
                    if (window.flutter_callbacks && window.flutter_callbacks.onIceCandidate) {
                        window.flutter_callbacks.onIceCandidate(event.candidate);
                    }
                }
            };
            
            // Handle remote stream
            this.peerConnection.ontrack = (event) => {
                console.log('🎵 Remote track received');
                this.remoteStream = event.streams[0];
                if (this.onRemoteStreamCallback) {
                    this.onRemoteStreamCallback(this.remoteStream);
                }
            };
            
            // Handle connection state changes
            this.peerConnection.onconnectionstatechange = () => {
                console.log('🔗 Connection state:', this.peerConnection.connectionState);
                if (this.peerConnection.connectionState === 'connected') {
                    if (this.onCallConnectedCallback) {
                        this.onCallConnectedCallback();
                    }
                } else if (this.peerConnection.connectionState === 'disconnected' || 
                          this.peerConnection.connectionState === 'failed') {
                    this.endCall();
                }
            };
            
            // Add local stream tracks
            if (this.localStream) {
                this.localStream.getTracks().forEach(track => {
                    this.peerConnection.addTrack(track, this.localStream);
                });
            }
            
            console.log('✅ Peer connection created');
            return this.peerConnection;
        } catch (error) {
            console.error('❌ Failed to create peer connection:', error);
            if (this.onErrorCallback) {
                this.onErrorCallback(`Failed to create peer connection: ${error.message}`);
            }
            throw error;
        }
    }
    
    // Create offer
    async createOffer() {
        try {
            const offer = await this.peerConnection.createOffer();
            await this.peerConnection.setLocalDescription(offer);
            console.log('📤 Created offer');
            return offer;
        } catch (error) {
            console.error('❌ Failed to create offer:', error);
            throw error;
        }
    }
    
    // Create answer
    async createAnswer(offer) {
        try {
            await this.peerConnection.setRemoteDescription(offer);
            const answer = await this.peerConnection.createAnswer();
            await this.peerConnection.setLocalDescription(answer);
            console.log('📥 Created answer');
            return answer;
        } catch (error) {
            console.error('❌ Failed to create answer:', error);
            throw error;
        }
    }
    
    // Set remote description
    async setRemoteDescription(description) {
        try {
            await this.peerConnection.setRemoteDescription(description);
            console.log('✅ Set remote description');
        } catch (error) {
            console.error('❌ Failed to set remote description:', error);
            throw error;
        }
    }
    
    // Add ICE candidate
    async addIceCandidate(candidate) {
        try {
            await this.peerConnection.addIceCandidate(candidate);
            console.log('✅ Added ICE candidate');
        } catch (error) {
            console.error('❌ Failed to add ICE candidate:', error);
        }
    }
    
    // Toggle mute
    toggleMute() {
        if (this.localStream) {
            const audioTrack = this.localStream.getAudioTracks()[0];
            if (audioTrack) {
                audioTrack.enabled = !audioTrack.enabled;
                this.isMuted = !audioTrack.enabled;
                console.log(this.isMuted ? '🔇 Microphone muted' : '🔊 Microphone unmuted');
            }
        }
        return this.isMuted;
    }
    
    // Toggle video
    toggleVideo() {
        if (this.localStream) {
            const videoTrack = this.localStream.getVideoTracks()[0];
            if (videoTrack) {
                videoTrack.enabled = !videoTrack.enabled;
                this.isVideoOn = videoTrack.enabled;
                console.log(this.isVideoOn ? '📹 Video enabled' : '📹 Video disabled');
            }
        }
        return this.isVideoOn;
    }
    
    // End call
    endCall() {
        console.log('📞 Ending call...');
        
        // Stop local stream
        if (this.localStream) {
            this.localStream.getTracks().forEach(track => track.stop());
            this.localStream = null;
        }
        
        // Close peer connection
        if (this.peerConnection) {
            this.peerConnection.close();
            this.peerConnection = null;
        }
        
        this.isInCall = false;
        this.remoteStream = null;
        
        if (this.onCallEndedCallback) {
            this.onCallEndedCallback();
        }
        
        console.log('✅ Call ended and resources cleaned up');
    }
    
    // Get call status
    getCallStatus() {
        return {
            isInCall: this.isInCall,
            isMuted: this.isMuted,
            isVideoOn: this.isVideoOn,
            connectionState: this.peerConnection ? this.peerConnection.connectionState : 'new'
        };
    }
}

// Global instance
window.webRTCWeb = new WebRTCWeb();

// Expose methods to Flutter
window.webRTCMethods = {
    initialize: () => window.webRTCWeb,
    getUserMedia: async (audioOnly) => await window.webRTCWeb.getUserMedia(audioOnly),
    createPeerConnection: () => window.webRTCWeb.createPeerConnection(),
    createOffer: async () => await window.webRTCWeb.createOffer(),
    createAnswer: async (offer) => await window.webRTCWeb.createAnswer(offer),
    setRemoteDescription: async (desc) => await window.webRTCWeb.setRemoteDescription(desc),
    addIceCandidate: async (candidate) => await window.webRTCWeb.addIceCandidate(candidate),
    toggleMute: () => window.webRTCWeb.toggleMute(),
    toggleVideo: () => window.webRTCWeb.toggleVideo(),
    endCall: () => window.webRTCWeb.endCall(),
    getCallStatus: () => window.webRTCWeb.getCallStatus(),
    setCallbacks: (callbacks) => window.webRTCWeb.setCallbacks(callbacks)
};

console.log('🌐 WebRTC Web JavaScript loaded');
