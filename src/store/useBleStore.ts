import { create } from "zustand";
import { Device } from "react-native-ble-plx";

type BleState = {
  device: Device | null;
  isConnected: boolean;
  isConnecting: boolean;

  setDevice: (device: Device | null) => void;
  setIsConnected: (value: boolean) => void;
  setIsConnecting: (value: boolean) => void;

  resetConnection: () => void;
};

export const useBleStore = create<BleState>((set) => ({
  device: null,
  isConnected: false,
  isConnecting: false,

  setDevice: (device) => set({ device }),
  setIsConnected: (value) => set({ isConnected: value }),
  setIsConnecting: (value) => set({ isConnecting: value }),

  resetConnection: () =>
    set({
      device: null,
      isConnected: false,
      isConnecting: false,
    }),
}));
