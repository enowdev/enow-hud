let config = null;
let isDraggingEnabled = false;
let dragElement = null;

// Profile settings dengan nilai default yang lebih spesifik
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
                stress: { opacity: 100 },
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
let settings = JSON.parse(JSON.stringify(profiles[currentProfile])); // Deep copy default profile

// Load settings dari localStorage
function loadSettings() {
    const savedSettings = localStorage.getItem('hudSettings');
    if (savedSettings) {
        settings = JSON.parse(savedSettings);
        applySettings();
    }
}

// Apply settings ke HUD
function applySettings() {
    const statusHud = document.getElementById('status-hud');
    const vehicleHud = document.getElementById('vehicle-hud');

    if (statusHud) {
        // Apply main status HUD settings
        const statusSettings = settings.statusHud;
        statusHud.style.backgroundColor = `${statusSettings.backgroundColor}${Math.floor(statusSettings.opacity * 2.55).toString(16).padStart(2, '0')}`;
        statusHud.style.transform = `scale(${statusSettings.scale / 100})`;
        statusHud.style.left = `${statusSettings.position.x}px`;
        statusHud.style.top = `${statusSettings.position.y}px`;

        // Apply individual element opacities
        Object.entries(statusSettings.elements).forEach(([element, values]) => {
            const elementDiv = statusHud.querySelector(`.${element}`);
            if (elementDiv) {
                elementDiv.style.opacity = values.opacity / 100;
            }
        });
    }

    if (vehicleHud) {
        const vehicleSettings = settings.vehicleHud;
        vehicleHud.style.backgroundColor = `${vehicleSettings.backgroundColor}${Math.floor(vehicleSettings.opacity * 2.55).toString(16).padStart(2, '0')}`;
        vehicleHud.style.transform = `scale(${vehicleSettings.scale / 100})`;
        vehicleHud.style.left = `${vehicleSettings.position.x}px`;
        vehicleHud.style.top = `${vehicleSettings.position.y}px`;
    }
}

// Edit panel functionality
window.addEventListener('message', function(event) {
    let data = event.data;
    
    switch(data.action) {
        case 'toggleHud':
            const elements = [
                document.getElementById('status-hud'),
                document.getElementById('vehicle-hud'),
                document.querySelector('.minimap-outline')
            ];
            
            elements.forEach(element => {
                if (element) {
                    element.style.display = data.show ? 'block' : 'none';
                }
            });
            break;
            
        case 'updateStatus':
            updateAllStatus(data);
            break;
            
        case 'updateVehicle':
            updateVehicleHUD(data);
            break;
            
        case 'updateVoice':
            updateVoiceHUD(data.voice);
            break;
            
        case 'toggleMinimapBorder':
            toggleMinimapBorder(data.show);
            break;
    }
});

function toggleMinimapBorder(show) {
    const border = document.querySelector('.minimap-outline');
    if (border) {
        border.style.display = show ? 'block' : 'none';
    }
}

function toggleHUD(show) {
    const statusHud = document.getElementById('status-hud');
    const vehicleHud = document.getElementById('vehicle-hud');
    
    if (statusHud) {
        statusHud.style.display = show ? 'block' : 'none';
    }
    
    // Only hide vehicle HUD if it's currently shown
    if (vehicleHud && vehicleHud.style.display !== 'none') {
        vehicleHud.style.display = show ? 'block' : 'none';
    }
    
    // Also toggle minimap border if it exists
    const minimapBorder = document.querySelector('.minimap-outline');
    if (minimapBorder) {
        minimapBorder.style.display = show ? 'block' : 'none';
    }
}

// Color picker handlers
document.querySelectorAll('input[type="color"]').forEach(input => {
    input.addEventListener('change', (e) => {
        const target = e.target.dataset.target;
        const hudElement = document.getElementById(target);
        settings[target === 'status-hud' ? 'statusHud' : 'vehicleHud'].backgroundColor = e.target.value;
        applySettings();
    });
});

// Opacity handlers
document.querySelectorAll('input[type="range"]').forEach(input => {
    input.addEventListener('input', (e) => {
        const target = e.target.id.includes('status') ? 'statusHud' : 'vehicleHud';
        settings[target].opacity = parseInt(e.target.value);
        applySettings();
    });
});

// Drag and Drop functionality
function enableDragging() {
    const huds = [
        { element: document.getElementById('status-hud'), key: 'statusHud' },
        { element: document.getElementById('vehicle-hud'), key: 'vehicleHud' }
    ];

    huds.forEach(({ element, key }) => {
        if (!element) return;
        
        // Reset styles yang mungkin mempengaruhi dragging
        element.style.width = 'auto';
        element.style.height = 'auto';
        element.classList.add('draggable');
        
        element.onmousedown = function(e) {
            if (!isDraggingEnabled) return;
            e.preventDefault();
            
            const rect = element.getBoundingClientRect();
            dragElement = {
                element: element,
                key: key,
                offsetX: e.clientX - rect.left,
                offsetY: e.clientY - rect.top,
                startWidth: rect.width,
                startHeight: rect.height
            };
            
            element.style.cursor = 'grabbing';
            element.classList.add('dragging');
        };
    });

    document.onmousemove = function(e) {
        if (!dragElement) return;
        e.preventDefault();
        
        const x = e.clientX - dragElement.offsetX;
        const y = e.clientY - dragElement.offsetY;
        
        // Batasan untuk tetap dalam window
        const maxX = window.innerWidth - dragElement.startWidth;
        const maxY = window.innerHeight - dragElement.startHeight;
        
        const boundedX = Math.max(0, Math.min(x, maxX));
        const boundedY = Math.max(0, Math.min(y, maxY));
        
        // Update posisi
        dragElement.element.style.left = `${boundedX}px`;
        dragElement.element.style.top = `${boundedY}px`;
        
        // Update settings
        settings[dragElement.key].position = { x: boundedX, y: boundedY };
    };

    document.onmouseup = function() {
        if (!dragElement) return;
        
        dragElement.element.style.cursor = 'grab';
        dragElement.element.classList.remove('dragging');
        dragElement = null;
    };
}

// Toggle drag mode
document.getElementById('enable-drag').addEventListener('change', function(e) {
    isDraggingEnabled = e.target.checked;
    const huds = document.querySelectorAll('#status-hud, #vehicle-hud');
    
    huds.forEach(hud => {
        if (isDraggingEnabled) {
            hud.classList.add('draggable');
            hud.style.cursor = 'grab';
        } else {
            hud.classList.remove('draggable');
            hud.style.cursor = 'default';
            hud.style.width = 'auto';  // Reset width
            hud.style.height = 'auto'; // Reset height
        }
    });

    if (isDraggingEnabled) {
        enableDragging();
    }
});

// Reset to Default Profile
function resetToDefault() {
    // Deep copy dari profile default
    settings = JSON.parse(JSON.stringify(profiles.default));
    
    // Reset background colors
    document.querySelectorAll('input[type="color"]').forEach(input => {
        const target = input.dataset.target === 'status-hud' ? 'statusHud' : 'vehicleHud';
        input.value = settings[target].backgroundColor;
    });

    // Reset main opacity dan scale sliders
    document.querySelectorAll('input[type="range"]').forEach(input => {
        const target = input.id.includes('status') ? 'statusHud' : 'vehicleHud';
        let value;
        
        if (input.id.includes('opacity')) {
            value = settings[target].opacity;
        } else if (input.id.includes('scale')) {
            value = settings[target].scale;
        } else {
            // Reset individual element opacities
            const elementMatch = input.id.match(/^(\w+)-opacity$/);
            if (elementMatch && settings.statusHud.elements[elementMatch[1]]) {
                value = settings.statusHud.elements[elementMatch[1]].opacity;
            }
        }
        
        if (value !== undefined) {
            input.value = value;
            if (input.nextElementSibling) {
                input.nextElementSibling.textContent = `${value}%`;
            }
        }
    });

    // Reset positions
    const statusHud = document.getElementById('status-hud');
    const vehicleHud = document.getElementById('vehicle-hud');

    if (statusHud) {
        statusHud.style.left = `${settings.statusHud.position.x}px`;
        statusHud.style.top = `${settings.statusHud.position.y}px`;
    }

    if (vehicleHud) {
        vehicleHud.style.left = `${settings.vehicleHud.position.x}px`;
        vehicleHud.style.top = `${settings.vehicleHud.position.y}px`;
    }

    // Apply all settings
    applySettings();

    // Visual feedback
    const button = document.getElementById('reset-settings');
    button.innerHTML = '<i class="fas fa-check"></i> Reset Complete!';
    button.style.background = '#27ae60';
    
    setTimeout(() => {
        button.innerHTML = '<i class="fas fa-undo"></i> Reset to Default';
        button.style.background = '#e74c3c';
    }, 1000);
}

document.getElementById('reset-settings').addEventListener('click', resetToDefault);

// Save settings
document.getElementById('save-settings').addEventListener('click', function() {
    localStorage.setItem('hudSettings', JSON.stringify(settings));
    
    fetch('https://enow-hud/saveSettings', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(settings)
    });

    // Visual feedback
    const button = this;
    button.innerHTML = '<i class="fas fa-check"></i> Saved!';
    button.style.background = '#27ae60';
    
    setTimeout(() => {
        button.innerHTML = '<i class="fas fa-save"></i> Save Changes';
        button.style.background = '#2ecc71';
        document.getElementById('edit-panel').style.display = 'none';
        fetch('https://enow-hud/closeMenu', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }, 1000);
});

function updateAllStatus(data) {
    // Update health
    if (data.health !== undefined) {
        document.querySelector('.health .fill').style.width = `${data.health}%`;
    }
    
    // Update armor
    if (data.armor !== undefined) {
        document.querySelector('.armor .fill').style.width = `${data.armor}%`;
    }
    
    // Update hunger
    if (data.hunger !== undefined) {
        document.querySelector('.hunger .fill').style.width = `${data.hunger}%`;
    }
    
    // Update thirst
    if (data.thirst !== undefined) {
        document.querySelector('.thirst .fill').style.width = `${data.thirst}%`;
    }
    
    // Update stress
    if (data.stress !== undefined) {
        document.querySelector('.stress .fill').style.width = `${data.stress}%`;
    }
}

function updateVehicleHUD(data) {
    const vehicleHud = document.getElementById('vehicle-hud');
    
    if (data.show) {
        vehicleHud.style.display = 'block';
        
        // Update speed
        document.querySelector('.speed .value').textContent = data.speed;
        
        // Update fuel
        const fuelPercent = data.fuel;
        document.querySelector('.fuel .fill').style.width = `${fuelPercent}%`;
        document.querySelector('.fuel .value').textContent = Math.ceil(fuelPercent);
        
        // Update engine
        const enginePercent = data.engine;
        const engineElement = document.querySelector('.engine');
        if (engineElement) {
            const engineFill = engineElement.querySelector('.fill');
            const engineValue = engineElement.querySelector('.value');
            
            if (engineFill) engineFill.style.width = `${enginePercent}%`;
            if (engineValue) engineValue.textContent = Math.ceil(enginePercent);
            
            // Change color based on engine health
            let engineColor;
            if (enginePercent > 75) {
                engineColor = '#2ecc71'; // Green
            } else if (enginePercent > 40) {
                engineColor = '#f1c40f'; // Yellow
            } else {
                engineColor = '#e74c3c'; // Red
            }
            
            if (engineFill) engineFill.style.backgroundColor = engineColor;
            const engineIcon = engineElement.querySelector('i');
            if (engineIcon) engineIcon.style.color = engineColor;
        }
        
        // Update seatbelt
        const seatbeltElement = document.querySelector('.seatbelt');
        if (seatbeltElement) {
            if (data.seatbelt) {
                seatbeltElement.classList.add('active');
            } else {
                seatbeltElement.classList.remove('active');
            }
        }
    } else {
        vehicleHud.style.display = 'none';
    }
}

// Update close button untuk mengirim callback ke client
document.querySelector('.close-btn').addEventListener('click', () => {
    document.getElementById('edit-panel').style.display = 'none';
    fetch('https://enow-hud/closeMenu', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
});

function updateVoiceHUD(voiceData) {
    const voiceElement = document.querySelector('.voice');
    if (!voiceElement) return;

    const voiceFill = voiceElement.querySelector('.fill');
    const voiceIcon = voiceElement.querySelector('i');

    // Update voice level indicator
    if (voiceFill) {
        voiceFill.style.width = `${voiceData.level}%`;
    }

    // Update voice icon and color based on level
    if (voiceIcon) {
        // Update talking state
        if (voiceData.talking) {
            voiceElement.classList.add('talking');
        } else {
            voiceElement.classList.remove('talking');
        }

        // Update color based on level
        let color;
        if (voiceData.level <= 33) {
            color = '#95a5a6'; // Whisper
        } else if (voiceData.level <= 66) {
            color = '#2ecc71'; // Normal
        } else {
            color = '#e74c3c'; // Shout
        }
        
        voiceIcon.style.color = color;
        if (voiceFill) voiceFill.style.backgroundColor = color;
    }
}

// Update message handler
window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'updateVoice') {
        updateVoiceHUD(data);
    }
});

// Update nilai slider saat berubah
document.querySelectorAll('input[type="range"]').forEach(slider => {
    slider.addEventListener('input', (e) => {
        e.target.nextElementSibling.textContent = `${e.target.value}%`;
        
        const target = e.target.id.includes('status') ? 'statusHud' : 'vehicleHud';
        if (e.target.id.includes('opacity')) {
            settings[target].opacity = parseInt(e.target.value);
        } else if (e.target.id.includes('scale')) {
            settings[target].scale = parseInt(e.target.value);
        }
        applySettings();
    });
});

// Update individual element opacity
function updateElementOpacity(elementId, value) {
    const element = elementId.replace('-opacity', '');
    if (settings.statusHud.elements[element]) {
        settings.statusHud.elements[element].opacity = parseInt(value);
        const elementDiv = document.querySelector(`.${element}`);
        if (elementDiv) {
            elementDiv.style.opacity = value / 100;
        }
    }
}

// Add event listeners for individual opacity sliders
document.querySelectorAll('input[type="range"]').forEach(slider => {
    slider.addEventListener('input', (e) => {
        const value = e.target.value;
        if (e.target.nextElementSibling) {
            e.target.nextElementSibling.textContent = `${value}%`;
        }
        
        if (e.target.id.includes('-opacity')) {
            updateElementOpacity(e.target.id, value);
        }
    });
});
