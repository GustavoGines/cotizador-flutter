import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter va después
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Firebase
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))
    implementation("com.google.firebase:firebase-analytics")
}

android {
    namespace = "com.example.cotizador_dolar_api"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.cotizador_dolar_api"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystoreProps = Properties()
            val propsFile = file("$rootDir/key.properties") // <-- ruta robusta
    
            println("🔎 Buscando key.properties en: ${propsFile.absolutePath}")
            if (propsFile.exists()) {
                println("✅ key.properties encontrado")
                keystoreProps.load(FileInputStream(propsFile))
    
                val storeFilePath = (keystoreProps["storeFile"] as String?)?.trim()
                val sp = (keystoreProps["storePassword"] as String?)?.trim()
                val ka = (keystoreProps["keyAlias"] as String?)?.trim()
                val kp = (keystoreProps["keyPassword"] as String?)?.trim()
    
                if (!storeFilePath.isNullOrEmpty()) {
                    storeFile = file(storeFilePath)
                    println("🔐 Usando keystore en: $storeFilePath")
                } else {
                    println("❌ storeFile está vacío en key.properties")
                }
    
                storePassword = sp
                keyAlias = ka
                keyPassword = kp
            } else {
                println("❌ No se encontró key.properties")
            }
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release") // asegurar esto
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

}

flutter {
    source = "../.."
}
