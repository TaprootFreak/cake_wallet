import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:convert';
import 'package:cw_decred/api/libdcrwallet_bindings.dart';

class PayloadResult {
  final String payload;
  final String err;
  final int errCode;

  const PayloadResult(this.payload, this.err, this.errCode);
}

// Executes the provided fn and converts the string response to a PayloadResult.
// Returns payload, error code, and error.
PayloadResult executePayloadFn({
  required Pointer<NativePayloadResult> fn(),
  required List<Pointer> ptrsToFree,
  bool skipErrorCheck = false,
}) {
  final result = fn();
  final jsonStr = result.ref.result.toDartString();
  freePointers(ptrsToFree);
  if (jsonStr == null) throw Exception("no json return from wallet library");
  final decoded = json.decode(jsonStr);

  final err = decoded["error"] ?? "";
  if (!skipErrorCheck) {
    checkErr(err);
  }

  final payload = decoded["payload"] ?? "";
  final errCode = decoded["errorcode"] ?? -1;
  return new PayloadResult(payload, err, errCode);
}

void freePointers(List<Pointer> ptrsToFree) {
  for (final ptr in ptrsToFree) {
    malloc.free(ptr);
  }
}

void checkErr(String err) {
  if (err == "") return;
  throw Exception(err);
}

extension StringUtil on String {
  Pointer<Utf8> toCString() => toNativeUtf8();
}

