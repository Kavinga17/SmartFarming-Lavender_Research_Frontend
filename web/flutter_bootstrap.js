{{flutter_js}}
{{flutter_build_config}}

_flutter.buildConfig.canvasKitBaseUrl = "https://unpkg.com/canvaskit-wasm@0.39.1/bin/";

_flutter.loader.load({
    onEntrypointLoaded: async function(engineInitializer) {
        const appRunner = await engineInitializer.initializeEngine({
            useColorEmoji: true,
        });
        await appRunner.runApp();
    }
});
