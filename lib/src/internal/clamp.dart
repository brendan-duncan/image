int clamp(int x, int a, int b) => x.clamp(a, b).toInt();

int clamp255(int x) => x.clamp(0, 255).toInt();
