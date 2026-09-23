from pathlib import Path

root = Path('native/flutter_v1/lib/features/live')
host_path = root / 'stream_host_live_screen.dart'
viewer_path = root / 'stream_viewer_live_screen.dart'

host = host_path.read_text()
if "import 'native_live_stage.dart';" not in host:
    host = host.replace(
        "import 'native_live_components.dart';\n",
        "import 'native_live_components.dart';\nimport 'native_live_stage.dart';\n",
        1,
    )
host = host.replace(
    "final quantity = gift.singleSendOnly ? 1 : rawQuantity.clamp(1, 100000);",
    "final quantity = rawQuantity.clamp(1, 100000);",
)
if 'NativeHostV2Stage(' not in host:
    host_build = host.index("  @override\n  Widget build(BuildContext context)")
    host_stage = host.index(
        "            if (call != null)\n              PartialCallStateBuilder<CallParticipantState?>(",
        host_build,
    )
    host_safe = host.index("            SafeArea(", host_stage)
    host_replacement = (
        "            if (call != null)\n"
        "              NativeHostV2Stage(\n"
        "                call: call,\n"
        "                cameraEnabled: _cameraEnabled,\n"
        "                activeCohostUserId: _activeCohostUserId,\n"
        "              )\n"
        "            else\n"
        "              const FvLiveBackground(icon: Icons.videocam_off_rounded),\n"
        "            const FvLiveGradient(),\n"
    )
    host = host[:host_stage] + host_replacement + host[host_safe:]
host_path.write_text(host)

viewer = viewer_path.read_text()
if "import 'native_live_stage.dart';" not in viewer:
    viewer = viewer.replace(
        "import 'native_live_components.dart';\n",
        "import 'native_live_components.dart';\nimport 'native_live_stage.dart';\n",
        1,
    )
viewer = viewer.replace(
    "    final quantity = gift.singleSendOnly\n"
    "        ? 1\n"
    "        : ((payload['quantity'] as num?)?.toInt() ?? 1).clamp(1, 100000);",
    "    final quantity = ((payload['quantity'] as num?)?.toInt() ?? 1).clamp(\n"
    "      1,\n"
    "      100000,\n"
    "    );",
)
viewer = viewer.replace(
    "    if (gift.singleSendOnly && quantity != 1) {\n"
    "      _showMessage('${gift.label} sends one at a time.');\n"
    "      return false;\n"
    "    }\n",
    "",
)
if 'NativeViewerV2Stage(' not in viewer:
    viewer_build = viewer.index("  @override\n  Widget build(BuildContext context)")
    viewer_stage = viewer.index(
        "              if (call != null)\n                PartialCallStateBuilder<List<CallParticipantState>>(",
        viewer_build,
    )
    viewer_safe = viewer.index("              SafeArea(", viewer_stage)
    viewer_replacement = (
        "              if (call != null)\n"
        "                NativeViewerV2Stage(\n"
        "                  call: call,\n"
        "                  hostUserId: widget.room.hostUserId,\n"
        "                  activeCohostUserId: _activeCohostUserId,\n"
        "                )\n"
        "              else\n"
        "                const FvLiveBackground(),\n"
        "              const FvLiveGradient(),\n"
    )
    viewer = viewer[:viewer_stage] + viewer_replacement + viewer[viewer_safe:]

gift_button = (
    "                          IconButton.filledTonal(\n"
    "                            onPressed: _walletReady ? _showGiftTray : null,\n"
    "                            icon: const Icon(Icons.card_giftcard_rounded),\n"
    "                            tooltip: 'Gifts',\n"
    "                          ),\n"
)
share_button = (
    "                          IconButton.filledTonal(\n"
    "                            onPressed: _shareLive,\n"
    "                            icon: const Icon(Icons.ios_share_rounded),\n"
    "                            tooltip: 'Share',\n"
    "                          ),\n"
)
if share_button not in viewer:
    viewer = viewer.replace(gift_button, gift_button + share_button, 1)
viewer_path.write_text(viewer)

# Native gift law: no gift can opt out of Custom Send.
live_backend = Path('native/flutter_v1/lib/data/fameverse_live_backend.dart')
backend_text = live_backend.read_text()
backend_text = backend_text.replace("    this.singleSendOnly = false,\n", "")
backend_text = backend_text.replace("  final bool singleSendOnly;\n", "")
live_backend.write_text(backend_text)

# Web/PWA gift law must match native: all gifts support Custom Send.
web_config = Path('src/config/gifts.js')
config_text = web_config.read_text().replace("    singleSendOnly: true,\n", "")
web_config.write_text(config_text)

web_tray = Path('src/components/gifts/LiveGiftTray.jsx')
tray_text = web_tray.read_text()
tray_text = tray_text.replace(
    """          {!selectedGift.singleSendOnly && (\n            <button type=\"button\" className=\"fv-gift-custom-open\" onClick={() => setCustomOpen(true)}>\n              Custom\n            </button>\n          )}\n""",
    """          <button type=\"button\" className=\"fv-gift-custom-open\" onClick={() => setCustomOpen(true)}>\n            Custom\n          </button>\n""",
)
tray_text = tray_text.replace(
    "        {customOpen && !selectedGift.singleSendOnly && (\n",
    "        {customOpen && (\n",
)
web_tray.write_text(tray_text)
