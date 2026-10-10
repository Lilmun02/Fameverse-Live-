import 'package:flutter/material.dart';

/// Read-only preview. Badge imports are not available during this private QA.
class NativeBadgeTransferPreview extends StatelessWidget {
  const NativeBadgeTransferPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('badge-transfer-preview-card'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF17111B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF513862)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: Color(0xFFD3A0FF)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bring your badge',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                'COMING SOON',
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFFD3A0FF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Future verified transfers from TikTok, Favorited, or EPIC.',
            style: TextStyle(color: Color(0xFFE8D9EF), fontSize: 12),
          ),
          SizedBox(height: 10),
          Text(
            'How it will work: record your source-app profile and earned badge in one screen recording. Your visible username and badge must match your claim. Fameverse reviews the proof before any conversion or approval.',
            style: TextStyle(
              color: Color(0xFFB8ACBC),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          SizedBox(height: 9),
          Text(
            'Only one supported source account can transfer. Mismatched proof will be denied; you may resubmit. Imports are not active yet, and badge-level equivalences are not final.',
            style: TextStyle(
              color: Color(0xFFB8ACBC),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
