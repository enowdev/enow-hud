let config = null;
let isDraggingEnabled = false;
let dragElement = null;

const profiles = {
    default: {
        statusHud: {
            backgroundColor: '#000000',
            opacity: 30,
            scale: 100,
            position: { x: 50, y: 920 },
            elements: {
                health: { opacity: 100 },
                armor: { opacity: 100 },
                hunger: { opacity: 100 },
                thirst: { opacity: 100 },
                voice: { opacity: 100 }
            }
        },
        vehicleHud: {
            backgroundColor: '#000000',
            opacity: 30,
            scale: 100,
            position: { x: 20, y: 800 }
        }
    }
};

let currentProfile = 'default';
let settings = JSON.parse(JSON.stringify(profiles[currentProfile]));

let currentSeatbeltState = false;

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'forceShowHUD') {
        const statusHud = document.getElementById('status-hud');
        
        if (statusHud) {
            statusHud.style.display = data.show ? 'block' : 'none';
            console.log('Status HUD visibility:', data.show);
        }
    }
    
    switch(data.action) {
        case 'toggleHUD':
            toggleHUD(data.show);
            break;
        case 'updateStatus':
            updateStatusBar('health', data.health);
            updateStatusBar('armor', data.armor);
            updateStatusBar('hunger', data.hunger);
            updateStatusBar('thirst', data.thirst);
            updateStatusBar('stamina', data.stamina);
            break;
        case 'hideStatus':
            const statusHud = document.getElementById('status-hud');
            if (statusHud) {
                statusHud.style.display = data.data ? 'none' : 'block';
            }
            break;
        case 'updateVehicle':
            const carContainer = document.querySelector('.car-container');
            if (!carContainer) return;

            if (data.show) {
                carContainer.style.display = 'block';
                
                const speedElement = document.querySelector('.speed .value');
                if (speedElement) {
                    speedElement.textContent = Math.round(data.speed || 0);
                }

                const fuelElement = document.querySelector('.fuel .value');
                const fuelBar = document.querySelector('.fuel .fill');
                if (fuelElement && fuelBar) {
                    const fuelValue = Math.round(data.fuel);
                    fuelElement.textContent = fuelValue + '%';
                    fuelBar.style.width = fuelValue + '%';
                }

                const engineElement = document.querySelector('.engine .value');
                const engineBar = document.querySelector('.engine .fill');
                if (engineElement && engineBar) {
                    const engineValue = Math.round(data.engine);
                    engineElement.textContent = engineValue + '%';
                    engineBar.style.width = engineValue + '%';
                }

                const seatbeltElement = document.querySelector('.seatbelt');
                if (seatbeltElement) {
                    if (data.seatbelt) {
                        seatbeltElement.classList.add('active');
                        seatbeltElement.querySelector('i').style.color = '#2ecc71';
                    } else {
                        seatbeltElement.classList.remove('active');
                        seatbeltElement.querySelector('i').style.color = '#e74c3c';
                    }
                }
            } else {
                carContainer.style.display = 'none';
            }
            break;
        case 'hideHUD':
            document.getElementById('status-hud').style.display = 'none';
            document.querySelector('.car-container').style.display = 'none';
            break;
            
        case 'showHUD':
            document.getElementById('status-hud').style.display = 'block';
            break;
            
        case 'voiceUpdate':
            const voiceElement = document.querySelector('.voice');
            if (data.isTalking) {
                voiceElement.classList.add('talking');
            } else {
                voiceElement.classList.remove('talking');
            }
            updateStatusBar('voice', data.voiceLevel * 33.33);
            break;
    }
});

function toggleMinimapBorder(show) {
    const border = document.querySelector('.minimap-outline');
    if (border) {
        border.style.display = show ? 'block' : 'none';
    }
}

function updateAllStatus(data) {
    if (!data) return;
    
    updateStatusBar('health', data.health);
    updateStatusBar('armor', data.armor);
    updateStatusBar('hunger', data.hunger);
    updateStatusBar('thirst', data.thirst);
    updateStatusBar('stamina', data.stamina);
}

function updateStatusBar(statusName, value) {
    const statusFill = document.querySelector(`.${statusName} .fill`);
    if (statusFill) {
        const clampedValue = Math.max(0, Math.min(100, value));
        statusFill.style.width = `${clampedValue}%`;
    }
}

function updateVoiceHUD(voiceData) {
    const voiceElement = document.querySelector('.voice');
    if (!voiceElement) return;

    const voiceFill = voiceElement.querySelector('.fill');
    const voiceIcon = voiceElement.querySelector('i');

    if (!voiceFill || !voiceIcon) return;

    voiceFill.style.width = `${voiceData.level || 75}%`;

    if (voiceData.talking) {
        voiceElement.classList.add('talking');
        voiceIcon.style.color = '#e74c3c';
    } else {
        voiceElement.classList.remove('talking');
        voiceIcon.style.color = '#2ecc71';
    }
}