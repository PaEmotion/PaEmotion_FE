allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}


plugins {
    // 안드로이드 앱 플러그인의 '버전'을 여기서 지정 (apply false 필수!)
    id("com.android.application") version "8.2.0" apply false


    // 구글 서비스 플러그인의 '버전'도 여기서 지정 (apply false 필수!)
    id("com.google.gms.google-services") version "4.3.15" apply false
}

