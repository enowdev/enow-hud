Config = {}

-- Server/City Name Configuration
Config.ServerName = {
    enabled = true,
    text = "Indonesia Indah Roleplay",
    position = {
        top = "20px",
        left = "50%"
    },
    style = {
        fontSize = "24px",
        fontWeight = "bold",
        letterSpacing = "2px",
        textTransform = "uppercase",
        background = "rgba(0, 0, 0, 0.3)",
        padding = "15px",
        borderRadius = "15px"
    }
}

-- Player Info Configuration
Config.PlayerInfo = {
    enabled = true,
    position = {
        top = "20px",
        right = "20px"
    },
    style = {
        width = "300px",
        background = "rgba(0, 0, 0, 0.3)",
        borderRadius = "8px",
        padding = "15px"
    },
    header = {
        text = "Identitas Player",
        background = "rgba(0, 0, 0, 0.3)",
        color = "white"
    },
    elements = {
        name = {
            enabled = true,
            label = "Nama",
            icon = "fa-user"
        },
        job = {
            enabled = true,
            label = "Pekerjaan",
            icon = "fa-briefcase"
        },
        cash = {
            enabled = true,
            label = "Saldo Cash",
            icon = "fa-wallet"
        },
        bank = {
            enabled = true,
            label = "Saldo Bank",
            icon = "fa-building-columns"
        }
    }
}

Config.ShowHealth = true
Config.ShowArmor = true
Config.ShowHunger = true
Config.ShowThirst = true
Config.ShowStress = true
Config.ShowMoney = true
Config.ShowJob = true

-- Posisi default HUD
Config.HudPosition = {
    x = 20,
    y = 20
}

-- Update interval (dalam milidetik)
Config.UpdateInterval = 1000

Config.MoneyUpdateInterval = 5000 -- Update uang setiap 5 detik
Config.FormatMoney = true -- Format uang dengan pemisah ribuan
Config.ShowBank = true -- Tampilkan saldo bank
Config.ShowJobGrade = true -- Tampilkan pangkat pekerjaan

Config.DisableHealthArmor = true
Config.DisableRadarOnFoot = true