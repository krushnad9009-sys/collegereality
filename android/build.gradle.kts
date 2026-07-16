fiimport com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    val configureCompileSdk = {
        if (plugins.hasPlugin("com.android.application") ||
            plugins.hasPlugin("com.android.library")
        ) {
            extensions.configure<BaseExtension>("android") {
                compileSdkVersion(36)
            }
        }
    }
    if (state.executed) {
        configureCompileSdk()
    } else {
        afterEvaluate { configureCompileSdk() }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
