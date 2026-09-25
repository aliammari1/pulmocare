# Changelog

## [1.1.0](https://github.com/aliammari1/pulmocare/compare/auth-service-v1.0.0...auth-service-v1.1.0) (2026-09-25)


### Features

* **auth:** add authenticated profile updates ([669853e](https://github.com/aliammari1/pulmocare/commit/669853e1674074a485f4e92a41dff8157e7cda44))
* **auth:** add profile and account update contracts ([cfb4671](https://github.com/aliammari1/pulmocare/commit/cfb46715e57d17893aed9a297b555c0495885e8c))
* **auth:** add provider identity lookup ([2250bb4](https://github.com/aliammari1/pulmocare/commit/2250bb4fc41b92ff0e72c26b94af2cd99697767a))
* **auth:** add provider verification workflow ([11ac3c8](https://github.com/aliammari1/pulmocare/commit/11ac3c8bc50561d494cbe2253136073ee799bc8d))
* **auth:** add safe provider directory ([1becf8c](https://github.com/aliammari1/pulmocare/commit/1becf8c3436a06dd40150889abe24dd96916dbbc))
* **auth:** add scoped patient contact lookup ([3668768](https://github.com/aliammari1/pulmocare/commit/36687689d69ee27425edddda966315658b743beb))
* **auth:** add verification decision contract ([3a25d64](https://github.com/aliammari1/pulmocare/commit/3a25d64e8cca20e7edebb86126735f8d6aa1684b))
* **auth:** support authenticated password changes ([8be7b2a](https://github.com/aliammari1/pulmocare/commit/8be7b2a7f966aa6bac20219bd96274b8bb764ea0))
* **auth:** support safe profile and password updates ([6e54f64](https://github.com/aliammari1/pulmocare/commit/6e54f64810fce826d041b483e75f87d2c2625a26))


### Bug Fixes

* **auth:** avoid loop-captured provider attribute helper ([fc1bddf](https://github.com/aliammari1/pulmocare/commit/fc1bddfaff2557cf6f8dca0d6ec95d7aa619fd77))
* **auth:** clear Ruff regressions after logging cleanup ([bc137f7](https://github.com/aliammari1/pulmocare/commit/bc137f7a72f89e8231e0a9356f51368211a46d48))
* **auth:** keep role lookup fallback lint-clean ([6faaf24](https://github.com/aliammari1/pulmocare/commit/6faaf248db6302384cda1e2a9978230bf8f380d4))
* **auth:** normalize Keycloak logging and reset flow ([39a9839](https://github.com/aliammari1/pulmocare/commit/39a9839b09dda5cedaf5acf9fe914698d4ee17b7))
* **auth:** normalize profile roles and account names ([824d297](https://github.com/aliammari1/pulmocare/commit/824d2979e4777160fbaf23ba13fd243689157c11))
* **auth:** preserve authorization failures and validate configured audience ([06769d5](https://github.com/aliammari1/pulmocare/commit/06769d57a2251516f30eaa9a524ab8ffa16813fa))
* **auth:** remove sensitive print debugging ([61242e5](https://github.com/aliammari1/pulmocare/commit/61242e59b61870da80ec1237a692406bef340df2))
* **auth:** repair token verification control flow ([8f1b54d](https://github.com/aliammari1/pulmocare/commit/8f1b54d48b1dc20c62ce8a80a35f288d14a7b212))
* **auth:** restrict registration and user enumeration ([5bcd901](https://github.com/aliammari1/pulmocare/commit/5bcd9014761c032c1df75dae82b3ecfdb916ce11))
* **ci:** resolve auth typing and report test blockers ([7c9d08e](https://github.com/aliammari1/pulmocare/commit/7c9d08e818bab887b0c47ebc680b198595e4706d))
* **ci:** unblock core validation ([d98fed8](https://github.com/aliammari1/pulmocare/commit/d98fed8719a2d936cab2ff84bc4ba4bc60996613))
* **core:** clear formatter and mobile test blockers ([6ba796e](https://github.com/aliammari1/pulmocare/commit/6ba796ef1425c01d78dbe0be7f92627cecd26998))
* **mobile:** correct report trend date iteration ([4d90586](https://github.com/aliammari1/pulmocare/commit/4d9058608f8e1e48281ec544f91d7e101799e610))
* **mobile:** resolve secure storage dependency conflict ([6ae8aea](https://github.com/aliammari1/pulmocare/commit/6ae8aea628ea6a562b994fc830a12c6d75f59174))
