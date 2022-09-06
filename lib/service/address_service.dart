import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:etherwallet/service/configuration_service.dart';
import 'package:hex/hex.dart';
import 'package:web3dart/credentials.dart';
import 'package:bip32/bip32.dart' as bip32;

abstract class IAddressService {
  String generateMnemonic();
  Future<String> getPrivateKey(String mnemonic);
  Future<EthereumAddress> getPublicAddress(String privateKey);
  Future<bool> setupFromMnemonic(String mnemonic);
  Future<bool> setupFromPrivateKey(String privateKey);
  String entropyToMnemonic(String entropyMnemonic);
}

class AddressService implements IAddressService {
  const AddressService(this._configService);

  final IConfigurationService _configService;

  @override
  String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  @override
  String entropyToMnemonic(String entropyMnemonic) {
    return bip39.entropyToMnemonic(entropyMnemonic);
  }

  @override
  Future<String> getPrivateKey(String mnemonic) async {
    final seed = bip39.mnemonicToSeedHex(mnemonic);
    final bip32.BIP32 root = bip32.BIP32.fromSeed(HEX.decode(seed) as Uint8List);
    final bip32.BIP32 child = root.derivePath("m/44'/60'/0'/0/0"); // <--- this is what you looking for. 0 will give you the first address and then you can iterate.
    final privateKey = HEX.encode(child.privateKey as Uint8List);
    print('private: $privateKey');
    return privateKey;
  }

  @override
  Future<EthereumAddress> getPublicAddress(String privateKey) async {
    final private = EthPrivateKey.fromHex(privateKey);

    final address = await private.extractAddress();
    print('address: $address');
    return address;
  }

  @override
  Future<bool> setupFromMnemonic(String mnemonic) async {
    final cryptMnemonic = bip39.mnemonicToEntropy(mnemonic);
    final privateKey = await getPrivateKey(mnemonic);

    await _configService.setMnemonic(cryptMnemonic);
    await _configService.setPrivateKey(privateKey);
    await _configService.setupDone(true);
    return true;
  }

  @override
  Future<bool> setupFromPrivateKey(String privateKey) async {
    await _configService.setMnemonic(null);
    await _configService.setPrivateKey(privateKey);
    await _configService.setupDone(true);
    return true;
  }
}
