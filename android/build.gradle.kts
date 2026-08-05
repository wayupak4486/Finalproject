import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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
    project.evaluationDependsOn(":app")

    // Android libraries default to Java 17, while tflite_flutter declares
    // Java 11. Match Kotlin to each library's Java bytecode target.
    val kotlinJvmTarget = if (name == "tflite_flutter") {
        JvmTarget.JVM_11
    } else {
        JvmTarget.JVM_17
    }

    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions.jvmTarget.set(kotlinJvmTarget)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
