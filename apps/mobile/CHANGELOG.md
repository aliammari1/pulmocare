# Changelog

## [0.2.0](https://github.com/aliammari1/pulmocare/compare/mobile-v0.1.0...mobile-v0.2.0) (2026-09-25)


### Features

* **mobile:** add appointment booking API ([91b35bf](https://github.com/aliammari1/pulmocare/commit/91b35bfca94556b02bf30b64405b8f4fb3266729))
* **mobile:** add assistant chat message model ([2a5eefd](https://github.com/aliammari1/pulmocare/commit/2a5eefd76b688592dce1cc3ff493e12b48b22e78))
* **mobile:** add authenticated medical file uploads ([a957691](https://github.com/aliammari1/pulmocare/commit/a9576915d728642eeefbc8098b7f410a5c793dae))
* **mobile:** add clinical provider model ([7d7af27](https://github.com/aliammari1/pulmocare/commit/7d7af277162f245fbf2f6d8fabf66689f4e02395))
* **mobile:** add complete appointment booking dialog ([b23c7eb](https://github.com/aliammari1/pulmocare/commit/b23c7ebf30b6cad7eb9223dc73d9a5fd2b4f9ae9))
* **mobile:** add functional profile and password actions ([0e9b69c](https://github.com/aliammari1/pulmocare/commit/0e9b69ce845a9595d821559a1c4e04f8c85c6377))
* **mobile:** add live patient picker ([fa7771b](https://github.com/aliammari1/pulmocare/commit/fa7771b19359898219d981d79891a0f134cd971f))
* **mobile:** add provider directory client ([10ee9b4](https://github.com/aliammari1/pulmocare/commit/10ee9b4de92b07aa94bed5e8489a02b8dd843ccf))
* **mobile:** add server-backed clinical assistant client ([d5f2510](https://github.com/aliammari1/pulmocare/commit/d5f2510e19bb89f839c5bbbc51a4d883c305279d))
* **mobile:** attach reports to real patient accounts ([d52f437](https://github.com/aliammari1/pulmocare/commit/d52f4374476e0c3b6f0276c6bb78d686cd8ee9e2))
* **mobile:** complete account and verification flows ([d2e7af9](https://github.com/aliammari1/pulmocare/commit/d2e7af9cac227e05e4bb3cd4cf5f95a7ecb7614e))
* **mobile:** complete and polish account management ([bb96e55](https://github.com/aliammari1/pulmocare/commit/bb96e555b51485560b93eac9c0608924c9e40d31))
* **mobile:** complete report edit and role-aware actions ([e888805](https://github.com/aliammari1/pulmocare/commit/e88880553e32741956ec6d5f26771234ee816380))
* **mobile:** connect appointment booking to live API ([7602981](https://github.com/aliammari1/pulmocare/commit/760298102125254bc733baaf6d057ee8e427b377))
* **mobile:** expose authenticated clinical assistant ([ff14b9a](https://github.com/aliammari1/pulmocare/commit/ff14b9a86d08073ada4480efef6ae52b0f0f4f1d))
* **mobile:** expose live report creation to clinicians ([978b542](https://github.com/aliammari1/pulmocare/commit/978b5421bfcb79ba45374edf970d695b461ace5f))
* **mobile:** make provider verification submission real ([a2bb3fc](https://github.com/aliammari1/pulmocare/commit/a2bb3fcf4ef435470b459f66e20a07afaf202e70))
* **mobile:** rebuild auth session and core clinical UI ([0381e74](https://github.com/aliammari1/pulmocare/commit/0381e74c9107ca517151f23118ab3927b3e9f256))
* **mobile:** refine responsive clinical workspace UI ([4588c07](https://github.com/aliammari1/pulmocare/commit/4588c078abddfcd3e6f4020efc2cf9170e7bc33a))
* **mobile:** restore backend clinical assistant UI ([5d5bb3b](https://github.com/aliammari1/pulmocare/commit/5d5bb3bb8bcd2a77824300bc119458f44ac858ec))
* **mobile:** restore prescription feature providers and routes ([2607837](https://github.com/aliammari1/pulmocare/commit/26078377a748125f1a0110c7f3fa787c8c8313cc))
* **mobile:** wire account actions to auth API ([5408279](https://github.com/aliammari1/pulmocare/commit/54082795503793acc52300f822d87eb2fc0f9213))


### Bug Fixes

* **ci:** resolve auth typing and report test blockers ([7c9d08e](https://github.com/aliammari1/pulmocare/commit/7c9d08e818bab887b0c47ebc680b198595e4706d))
* **core:** clear formatter and mobile test blockers ([6ba796e](https://github.com/aliammari1/pulmocare/commit/6ba796ef1425c01d78dbe0be7f92627cecd26998))
* **mobile:** align prescriptions with live API ([58fe623](https://github.com/aliammari1/pulmocare/commit/58fe623afb9038be60bc0a6fcee1c71658e765ed))
* **mobile:** allow Dio to select multipart content type ([3dbb0a5](https://github.com/aliammari1/pulmocare/commit/3dbb0a579bcb18fabff6f9c8ebf97b9655c0489a))
* **mobile:** clear Flutter compile blockers ([978e997](https://github.com/aliammari1/pulmocare/commit/978e9972c640f2aae78b10f70bae329ba17fbabb))
* **mobile:** consolidate account mutation methods ([0a85947](https://github.com/aliammari1/pulmocare/commit/0a8594776d830867477de8a76d895e996e334bb3))
* **mobile:** correct report trend date iteration ([4d90586](https://github.com/aliammari1/pulmocare/commit/4d9058608f8e1e48281ec544f91d7e101799e610))
* **mobile:** handle widget lifetime and scrub console logs ([c30c151](https://github.com/aliammari1/pulmocare/commit/c30c1513f623bdc39bd93dd3bb008c6fae97e5ee))
* **mobile:** harden Android runtime and platform configuration ([4e653f6](https://github.com/aliammari1/pulmocare/commit/4e653f620832cd61db49debe54c284241b460f40))
* **mobile:** load meaningful appointment history ([2045bea](https://github.com/aliammari1/pulmocare/commit/2045bea417a80fb0c808dc6c21af9e13da727575))
* **mobile:** make session restore compatible with token rotation ([33e226b](https://github.com/aliammari1/pulmocare/commit/33e226bf0daa41e3a98c941960dfece5fd5be704))
* **mobile:** parse canonical prescription records ([43c22be](https://github.com/aliammari1/pulmocare/commit/43c22be0b98d24f856339a69995892f20590f65f))
* **mobile:** persist created reports through live API ([0630d42](https://github.com/aliammari1/pulmocare/commit/0630d4210d1bbab542c5b7ae32f18fb30d4857d1))
* **mobile:** refresh expired sessions in Dio client ([a2fa413](https://github.com/aliammari1/pulmocare/commit/a2fa413904ea23959ff455a59d82de90c2ea2587))
* **mobile:** repair prescription analyzer errors ([1ef6a61](https://github.com/aliammari1/pulmocare/commit/1ef6a61a0981ff87f803b0c45a5208a7043414e5))
* **mobile:** replace demo clinical data with live service flows ([4c55999](https://github.com/aliammari1/pulmocare/commit/4c55999d6d8b988107c3c1b2565397f6a7b64805))
* **mobile:** replace deprecated color calls ([c8748fb](https://github.com/aliammari1/pulmocare/commit/c8748fb494920e85c7558de7e71e1927570f4a63))
* **mobile:** resolve secure storage dependency conflict ([6ae8aea](https://github.com/aliammari1/pulmocare/commit/6ae8aea628ea6a562b994fc830a12c6d75f59174))
* **mobile:** restrict bearer tokens and align renamed imports ([e73f057](https://github.com/aliammari1/pulmocare/commit/e73f0578d66f3502a6617e34ee3ce5bdb87438c2))
* **mobile:** update Android build toolchain ([a03f31e](https://github.com/aliammari1/pulmocare/commit/a03f31e37d8320aa65d6b0edb8effb6503c42983))
* **mobile:** upgrade speech plugin for current Gradle ([847c597](https://github.com/aliammari1/pulmocare/commit/847c5978cda140122b3a5600e48d8179b81d5fb1))
