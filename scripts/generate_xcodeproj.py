#!/usr/bin/env python3
"""Deterministically generates GoalieShotTracker.xcodeproj/project.pbxproj.

Kept as a standalone script (rather than a one-off hand-edited file) so the
project file can be regenerated if source files are added or moved later:
just extend APP_FILES / CORE_FILES below and re-run.
"""
import os
import re

REPO_ROOT = "/home/user/shot-tracker-"
APP_DIR = "GoalieShotTracker"
CORE_SRC_DIR = "Core/Sources/GoalieTrackerCore"
PROJECT_NAME = "GoalieShotTracker"
BUNDLE_ID = "com.kiddreads.goalieshottracker"

# ---------------------------------------------------------------------------
# File manifest (relative to APP_DIR / CORE_SRC_DIR respectively)
# ---------------------------------------------------------------------------

APP_FILES = [
    "GoalieShotTrackerApp.swift",
    "Persistence/Entities.swift",
    "Persistence/PersistenceController.swift",
    "Persistence/SampleData.swift",
    "Views/RootTabView.swift",
    "Views/Dashboard/DashboardView.swift",
    "Views/Logger/LogShotSheet.swift",
    "Views/Logger/NetDiagramView.swift",
    "Views/Logger/ShotLoggerView.swift",
    "Views/Logger/StartGameSheet.swift",
    "Views/History/GameDetailView.swift",
    "Views/History/GameHistoryListView.swift",
    "Views/Analytics/AnalyticsView.swift",
    "Views/Analytics/TrendChartView.swift",
    "Views/Analytics/ZoneHeatmapView.swift",
    "Views/Roster/GoalieEditView.swift",
    "Views/Roster/RosterView.swift",
    "Views/Roster/SettingsView.swift",
    "Views/Onboarding/OnboardingView.swift",
    "Views/Shared/AppState.swift",
    "Views/Shared/ChipRow.swift",
    "Views/Shared/CSVExporter.swift",
    "Views/Shared/GoalieStatsProvider.swift",
    "Views/Shared/StatTileView.swift",
    "Views/Shared/Theme.swift",
]

CORE_FILES = [
    "Enums/Badge.swift",
    "Enums/NetZone.swift",
    "Enums/ShotOutcome.swift",
    "Enums/ShotType.swift",
    "Enums/StrengthState.swift",
    "Models/GameSession.swift",
    "Models/GoalieProfile.swift",
    "Models/ShotEvent.swift",
    "Models/TeamAndOpponent.swift",
    "Stats/StatsEngine.swift",
    "Stats/StatsTypes.swift",
]

# Non-source resources, referenced but not compiled.
ENTITLEMENTS_FILE = "GoalieShotTracker.entitlements"
ASSETS_CATALOG = "Resources/Assets.xcassets"
PREVIEW_ASSETS = "Preview Content/Preview Assets.xcassets"

# ---------------------------------------------------------------------------
# ID generation
# ---------------------------------------------------------------------------

_counter = 0


def new_id():
    global _counter
    _counter += 1
    return f"{_counter:024X}"


# ---------------------------------------------------------------------------
# OpenStep plist serialization
# ---------------------------------------------------------------------------

_SAFE_RE = re.compile(r"^[A-Za-z0-9_$./:-]+$")


def pbx_str(s):
    s = str(s)
    if s != "" and _SAFE_RE.match(s):
        return s
    escaped = s.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def serialize(value, indent=0):
    pad = "\t" * indent
    pad_in = "\t" * (indent + 1)
    if isinstance(value, dict):
        lines = ["{\n"]
        for k in value:
            v = value[k]
            lines.append(f"{pad_in}{pbx_str(k)} = {serialize(v, indent + 1)};\n")
        lines.append(f"{pad}}}")
        return "".join(lines)
    if isinstance(value, list):
        if not value:
            return "(\n" + pad + ")"
        lines = ["(\n"]
        for item in value:
            lines.append(f"{pad_in}{serialize(item, indent + 1)},\n")
        lines.append(f"{pad})")
        return "".join(lines)
    return pbx_str(value)


# ---------------------------------------------------------------------------
# Build the object graph
# ---------------------------------------------------------------------------

objects = {}  # id -> dict (insertion order = emission order)


def add(obj):
    oid = new_id()
    objects[oid] = obj
    return oid


file_refs = {}  # relative-from-repo-root path -> file ref id
build_files_sources = []  # PBXBuildFile ids for Sources phase
build_files_resources = []  # PBXBuildFile ids for Resources phase


def make_source_file_ref(name, path_from_group):
    fid = add({
        "isa": "PBXFileReference",
        "lastKnownFileType": "sourcecode.swift",
        "path": name,
        "sourceTree": "<group>",
    })
    return fid


def make_build_file(file_ref_id):
    return add({
        "isa": "PBXBuildFile",
        "fileRef": file_ref_id,
    })


def build_group_tree(files, base_group_path):
    """files: list of relative paths (using '/' separators) rooted at base_group_path.
    Returns (root_group_id, list_of_source_file_ref_ids_in_tree_order)."""
    tree = {}  # nested dict representing folders -> {"__files__": [(name, relpath)]}

    for rel in files:
        parts = rel.split("/")
        node = tree
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node.setdefault("__files__", []).append(parts[-1])

    ordered_file_refs = []

    def build_node(node, path_prefix):
        children_ids = []
        # subfolders first, alphabetical, then files, alphabetical (matches Xcode convention)
        for folder in sorted(k for k in node.keys() if k != "__files__"):
            sub_path = f"{path_prefix}/{folder}" if path_prefix else folder
            child_children = build_node(node[folder], sub_path)
            group_id = add({
                "isa": "PBXGroup",
                "children": child_children,
                "path": folder,
                "sourceTree": "<group>",
            })
            children_ids.append(group_id)
        for filename in sorted(node.get("__files__", [])):
            rel_path = f"{path_prefix}/{filename}" if path_prefix else filename
            fid = make_source_file_ref(filename, rel_path)
            file_refs[f"{base_group_path}/{rel_path}"] = fid
            ordered_file_refs.append(fid)
            children_ids.append(fid)
        return children_ids

    top_children = build_node(tree, "")
    return top_children, ordered_file_refs


app_group_children, app_source_refs = build_group_tree(APP_FILES, APP_DIR)
core_group_children, core_source_refs = build_group_tree(CORE_FILES, CORE_SRC_DIR)

for fid in app_source_refs + core_source_refs:
    build_files_sources.append(make_build_file(fid))

# --- Non-source resources -------------------------------------------------

entitlements_ref = add({
    "isa": "PBXFileReference",
    "lastKnownFileType": "text.plist.entitlements",
    "path": os.path.basename(ENTITLEMENTS_FILE),
    "sourceTree": "<group>",
})

assets_ref = add({
    "isa": "PBXFileReference",
    "lastKnownFileType": "folder.assetcatalog",
    "path": "Assets.xcassets",
    "sourceTree": "<group>",
})
build_files_resources.append(make_build_file(assets_ref))

preview_assets_ref = add({
    "isa": "PBXFileReference",
    "lastKnownFileType": "folder.assetcatalog",
    "path": "Preview Assets.xcassets",
    "sourceTree": "<group>",
})
build_files_resources.append(make_build_file(preview_assets_ref))

resources_group = add({
    "isa": "PBXGroup",
    "children": [assets_ref],
    "path": "Resources",
    "sourceTree": "<group>",
})

preview_content_group = add({
    "isa": "PBXGroup",
    "children": [preview_assets_ref],
    "path": "Preview Content",
    "sourceTree": "<group>",
})

# --- Top-level groups -------------------------------------------------

app_group = add({
    "isa": "PBXGroup",
    "children": app_group_children + [resources_group, preview_content_group, entitlements_ref],
    "path": APP_DIR,
    "sourceTree": "<group>",
})

core_group = add({
    "isa": "PBXGroup",
    "children": core_group_children,
    "name": "Core",
    "path": CORE_SRC_DIR,
    "sourceTree": "<group>",
})

product_ref = add({
    "isa": "PBXFileReference",
    "explicitFileType": "wrapper.application",
    "includeInIndex": "0",
    "path": f"{PROJECT_NAME}.app",
    "sourceTree": "BUILT_PRODUCTS_DIR",
})

products_group = add({
    "isa": "PBXGroup",
    "children": [product_ref],
    "name": "Products",
    "sourceTree": "<group>",
})

main_group = add({
    "isa": "PBXGroup",
    "children": [app_group, core_group, products_group],
    "sourceTree": "<group>",
})

# --- Build phases -------------------------------------------------

sources_phase = add({
    "isa": "PBXSourcesBuildPhase",
    "buildActionMask": "2147483647",
    "files": build_files_sources,
    "runOnlyForDeploymentPostprocessing": "0",
})

frameworks_phase = add({
    "isa": "PBXFrameworksBuildPhase",
    "buildActionMask": "2147483647",
    "files": [],
    "runOnlyForDeploymentPostprocessing": "0",
})

resources_phase = add({
    "isa": "PBXResourcesBuildPhase",
    "buildActionMask": "2147483647",
    "files": build_files_resources,
    "runOnlyForDeploymentPostprocessing": "0",
})

# --- Build configurations -------------------------------------------------

common_project_settings = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_ENABLE_OBJC_WEAK": "YES",
    "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
    "CLANG_WARN_BOOL_CONVERSION": "YES",
    "CLANG_WARN_COMMA": "YES",
    "CLANG_WARN_CONSTANT_CONVERSION": "YES",
    "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
    "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
    "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
    "CLANG_WARN_EMPTY_BODY": "YES",
    "CLANG_WARN_ENUM_CONVERSION": "YES",
    "CLANG_WARN_INFINITE_RECURSION": "YES",
    "CLANG_WARN_INT_CONVERSION": "YES",
    "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
    "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
    "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
    "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
    "CLANG_WARN_STRICT_PROTOTYPES": "YES",
    "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
    "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
    "CLANG_WARN_UNREACHABLE_CODE": "YES",
    "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
    "COPY_PHASE_STRIP": "NO",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
    "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
    "GCC_WARN_UNDECLARED_SELECTOR": "YES",
    "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
    "GCC_WARN_UNUSED_FUNCTION": "YES",
    "GCC_WARN_UNUSED_VARIABLE": "YES",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "MTL_FAST_MATH": "YES",
    "SDKROOT": "iphoneos",
    "SWIFT_VERSION": "5.0",
}

debug_only_project = {
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_TESTABILITY": "YES",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
}

release_only_project = {
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "VALIDATE_PRODUCT": "YES",
}

project_debug_config = add({
    "isa": "XCBuildConfiguration",
    "buildSettings": {**common_project_settings, **debug_only_project},
    "name": "Debug",
})

project_release_config = add({
    "isa": "XCBuildConfiguration",
    "buildSettings": {**common_project_settings, **release_only_project},
    "name": "Release",
})

project_config_list = add({
    "isa": "XCConfigurationList",
    "buildConfigurations": [project_debug_config, project_release_config],
    "defaultConfigurationIsVisible": "0",
    "defaultConfigurationName": "Release",
})

target_common_settings = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_ENTITLEMENTS": f"{APP_DIR}/{ENTITLEMENTS_FILE}",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_ASSET_PATHS": f"{APP_DIR}/Preview Content",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations~ipad": [
        "UIInterfaceOrientationPortrait",
        "UIInterfaceOrientationPortraitUpsideDown",
        "UIInterfaceOrientationLandscapeLeft",
        "UIInterfaceOrientationLandscapeRight",
    ],
    "INFOPLIST_KEY_NSHumanReadableCopyright": "",
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
}

target_debug_config = add({
    "isa": "XCBuildConfiguration",
    "buildSettings": dict(target_common_settings),
    "name": "Debug",
})

target_release_config = add({
    "isa": "XCBuildConfiguration",
    "buildSettings": dict(target_common_settings),
    "name": "Release",
})

target_config_list = add({
    "isa": "XCConfigurationList",
    "buildConfigurations": [target_debug_config, target_release_config],
    "defaultConfigurationIsVisible": "0",
    "defaultConfigurationName": "Release",
})

# --- Target & project -------------------------------------------------

native_target = add({
    "isa": "PBXNativeTarget",
    "buildConfigurationList": target_config_list,
    "buildPhases": [sources_phase, frameworks_phase, resources_phase],
    "buildRules": [],
    "dependencies": [],
    "name": PROJECT_NAME,
    "productName": PROJECT_NAME,
    "productReference": product_ref,
    "productType": "com.apple.product-type.application",
})

project_object = add({
    "isa": "PBXProject",
    "attributes": {
        "BuildIndependentTargetsInParallel": "1",
        "LastSwiftUpdateCheck": "1520",
        "LastUpgradeCheck": "1520",
        "ORGANIZATIONNAME": "Brandon Ward",
        "TargetAttributes": {
            native_target: {
                "CreatedOnToolsVersion": "15.2",
            },
        },
    },
    "buildConfigurationList": project_config_list,
    "compatibilityVersion": "Xcode 14.0",
    "developmentRegion": "en",
    "hasScannedForEncodings": "0",
    "knownRegions": ["en", "Base"],
    "mainGroup": main_group,
    "productRefGroup": products_group,
    "projectDirPath": "",
    "projectRoot": "",
    "targets": [native_target],
})

# ---------------------------------------------------------------------------
# Emit
# ---------------------------------------------------------------------------

root = {
    "archiveVersion": "1",
    "classes": {},
    "objectVersion": "56",
    "objects": objects,
    "rootObject": project_object,
}

output = "// !$*UTF8*$!\n" + serialize(root, 0) + "\n"

out_dir = os.path.join(REPO_ROOT, f"{PROJECT_NAME}.xcodeproj")
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, "project.pbxproj")
with open(out_path, "w") as f:
    f.write(output)

print(f"Wrote {out_path} ({len(objects)} objects, {len(app_source_refs)} app files, {len(core_source_refs)} core files)")

# ---------------------------------------------------------------------------
# Shared scheme (so `xcodebuild -list` / a fresh checkout has a Run scheme
# without the user needing to open Xcode and let it autogenerate one first)
# ---------------------------------------------------------------------------

scheme_dir = os.path.join(out_dir, "xcshareddata", "xcschemes")
os.makedirs(scheme_dir, exist_ok=True)

scheme_xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1520"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{native_target}"
               BuildableName = "{PROJECT_NAME}.app"
               BlueprintName = "{PROJECT_NAME}"
               ReferencedContainer = "container:{PROJECT_NAME}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{native_target}"
            BuildableName = "{PROJECT_NAME}.app"
            BlueprintName = "{PROJECT_NAME}"
            ReferencedContainer = "container:{PROJECT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{native_target}"
            BuildableName = "{PROJECT_NAME}.app"
            BlueprintName = "{PROJECT_NAME}"
            ReferencedContainer = "container:{PROJECT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
'''

scheme_path = os.path.join(scheme_dir, f"{PROJECT_NAME}.xcscheme")
with open(scheme_path, "w") as f:
    f.write(scheme_xml)
print(f"Wrote {scheme_path}")
