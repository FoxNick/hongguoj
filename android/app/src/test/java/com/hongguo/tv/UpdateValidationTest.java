package com.hongguo.tv;

import java.util.Set;

public final class UpdateValidationTest {
    private static int checks;
    private static final Set<String> SIGNER = Set.of(UpdateValidation.CERTIFICATE);

    private static void assertTrue(boolean value) {
        checks++;
        if (!value) throw new AssertionError("assertion " + checks);
    }

    private static void reject(Runnable action) {
        try { action.run(); } catch (IllegalArgumentException expected) { checks++; return; }
        throw new AssertionError("Expected rejection");
    }

    public static void main(String[] args) {
        String hash = "a".repeat(64);
        UpdateValidation.verifyBytes(4, 4, hash, hash);
        reject(() -> UpdateValidation.verifyBytes(4, 3, hash, hash));
        reject(() -> UpdateValidation.verifyBytes(4, 5, hash, hash));
        reject(() -> UpdateValidation.verifyBytes(0, 0, hash, hash));
        reject(() -> UpdateValidation.verifyBytes(UpdateValidation.MAXIMUM_BYTES + 1, UpdateValidation.MAXIMUM_BYTES + 1, hash, hash));
        reject(() -> UpdateValidation.verifyBytes(4, 4, hash, "b".repeat(64)));
        reject(() -> UpdateValidation.verifyBytes(4, 4, "bad", "bad"));
        for (String abi : new String[]{"armeabi-v7a", "arm64-v8a", "x86_64"}) {
            UpdateValidation.verifyIdentity(UpdateValidation.PACKAGE, UpdateValidation.PACKAGE, SIGNER, SIGNER,
                    31, 32, 32, abi, Set.of(abi), abi);
            reject(() -> UpdateValidation.verifyIdentity("com.hongguo.tv.debug", UpdateValidation.PACKAGE, SIGNER, SIGNER,
                    31, 32, 32, abi, Set.of(abi), abi));
            reject(() -> UpdateValidation.verifyIdentity(UpdateValidation.PACKAGE, "other.package", SIGNER, SIGNER,
                    31, 32, 32, abi, Set.of(abi), abi));
            reject(() -> UpdateValidation.verifyIdentity(UpdateValidation.PACKAGE, UpdateValidation.PACKAGE, Set.of("fake"), Set.of("fake"),
                    31, 32, 32, abi, Set.of(abi), abi));
            reject(() -> UpdateValidation.verifyIdentity(UpdateValidation.PACKAGE, UpdateValidation.PACKAGE, SIGNER, Set.of("fake"),
                    31, 32, 32, abi, Set.of(abi), abi));
            reject(() -> UpdateValidation.verifyIdentity(UpdateValidation.PACKAGE, UpdateValidation.PACKAGE, SIGNER, Set.of(UpdateValidation.CERTIFICATE, "extra"),
                    31, 32, 32, abi, Set.of(abi), abi));
            for (long code : new long[]{30, 31, 33, 1000}) {
                reject(() -> UpdateValidation.verifyIdentity(UpdateValidation.PACKAGE, UpdateValidation.PACKAGE, SIGNER, SIGNER,
                        31, code, 32, abi, Set.of(abi), abi));
            }
            reject(() -> UpdateValidation.verifyIdentity(UpdateValidation.PACKAGE, UpdateValidation.PACKAGE, SIGNER, SIGNER,
                    31, 32, 32, abi, Set.of("wrong"), abi));
            reject(() -> UpdateValidation.verifyIdentity(UpdateValidation.PACKAGE, UpdateValidation.PACKAGE, SIGNER, SIGNER,
                    31, 32, 32, abi, Set.of(abi, "wrong"), abi));
            reject(() -> UpdateValidation.verifyIdentity(UpdateValidation.PACKAGE, UpdateValidation.PACKAGE, SIGNER, SIGNER,
                    31, 32, 32, abi, Set.of(abi), "wrong"));
        }
        reject(() -> UpdateValidation.verifyIdentity(UpdateValidation.PACKAGE, UpdateValidation.PACKAGE, SIGNER, SIGNER,
                31, 32, 32, "mips", Set.of("mips"), "mips"));
        UpdateInstallSession session = new UpdateInstallSession();
        session.begin(4821);
        session.pause();
        assertTrue(session.resume() == 0);
        assertTrue(!session.canReturn(4821));
        assertTrue(session.launch(4821));
        session.pause();
        assertTrue(session.resume() == 4821);
        assertTrue(session.canReturn(4821));
        assertTrue(session.complete(4821));
        session.begin(4822);
        session.launch(4822);
        session.pause();
        session.resume();
        assertTrue(!session.canReturn(4821));
        assertTrue(!session.matches(4821));
        assertTrue(!session.complete(4821));
        assertTrue(session.canReturn(4822));
        session.pause();
        assertTrue(!session.canReturn(4822));
        assertTrue(session.matches(4822));
        System.out.println("Updater native policy/lifecycle assertions passed: " + checks);
    }
}
