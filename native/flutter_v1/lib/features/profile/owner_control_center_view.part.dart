part of 'owner_control_center_build23.dart';

extension _OwnerControlCenterView on _Build23OwnerControlCenterScreenState {
  Widget buildView(BuildContext context) {
    return Scaffold(
      key: const Key('build23-owner-control-center'),
      backgroundColor: const Color(0xFF0C0810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0810),
        title: const Text('Owner Studio'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
            children: [
              const _Hero(),
              if (widget.onOpenCreatorStudio != null) ...[
                const SizedBox(height: 12),
                _Action(
                  key: const Key('owner-open-personal-creator-studio'),
                  icon: Icons.workspace_premium_rounded,
                  title: 'My Creator Account',
                  body:
                      'Your creator earnings, verification progress, PayPal payout method and payout history live here. Owner moderation stays in Owner Studio.',
                  label: 'Open',
                  onTap: widget.onOpenCreatorStudio,
                ),
              ],
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 52),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _Notice(
                  icon: Icons.cloud_off_rounded,
                  title: 'Finance controls unavailable',
                  body: _error!,
                )
              else ...[
                const _Section('CREATOR VERIFICATION'),
                const SizedBox(height: 10),
                if (_verificationQueue.isEmpty)
                  const _Notice(
                    icon: Icons.verified_user_outlined,
                    title: 'No verification requests waiting',
                    body:
                        'Pending creator verification requests will appear here for owner review.',
                  )
                else
                  ..._verificationQueue.map(
                    (request) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VerificationReviewCard(
                        request: request,
                        busy: _busy,
                        onApprove: () =>
                            _reviewVerification(request, 'verified'),
                        onNeedsInfo: () =>
                            _reviewVerification(request, 'needs_info'),
                        onReject: () =>
                            _reviewVerification(request, 'rejected'),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const _Section('CREATOR PAYOUTS'),
                const SizedBox(height: 10),
                if (_payouts.isEmpty)
                  const _Notice(
                    icon: Icons.task_alt_rounded,
                    title: 'No payouts waiting',
                    body:
                        'Pending, approved and processing creator payouts will appear here for owner review.',
                  )
                else
                  ..._payouts.map(
                    (payout) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PayoutCard(
                        payout: payout,
                        busy: _busy,
                        onApprove: () => _reviewPayout(payout, 'approved'),
                        onHold: () => _reviewPayout(payout, 'held'),
                        onReject: () => _reviewPayout(payout, 'rejected'),
                        onProcess: () => _beginPayoutProcessing(payout),
                        onSync: () => _syncPayoutStatus(payout),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const _Section('PLATFORM FINANCES'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Platform share earned',
                        value: _money(
                          _int(_summary['platform_share_earned_cents']),
                        ),
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Metric(
                        label: 'Cash-backed gifts',
                        value: _money(
                          _int(_summary['cash_backed_gifts_gross_cents']),
                        ),
                        icon: Icons.card_giftcard_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Creator share earned',
                        value: _money(
                          _int(_summary['creator_share_earned_cents']),
                        ),
                        icon: Icons.people_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Metric(
                        label: 'Payouts in review',
                        value: _money(
                          _int(_summary['creator_payouts_in_review_cents']),
                        ),
                        icon: Icons.fact_check_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _Section('REWARD RESERVE & LIABILITIES'),
                const SizedBox(height: 10),
                _LiabilityCard(
                  reserveCents: _int(_summary['reward_reserve_cents']),
                  cashBackedOutstandingCents: _int(
                    _summary['cash_backed_value_outstanding_cents'],
                  ),
                  creatorUnpaidCents: _int(
                    _summary['creator_earnings_unpaid_cents'],
                  ),
                ),
                const SizedBox(height: 20),
                const _Section('FAME COIN BALANCES'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Promo Fame Coins · no cash value',
                        value: '${_int(_wallet['promo_coins'])}',
                        icon: Icons.science_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Metric(
                        label: 'Cash-Backed Fame Coins · real reserve',
                        value: '${_int(_wallet['cash_backed_coins'])}',
                        icon: Icons.attach_money_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _Section('REWARD FUNDING & OWNER BANKING'),
                const SizedBox(height: 10),
                _Action(
                  key: const Key('owner-grant-tester-test-coins'),
                  icon: Icons.science_outlined,
                  title: 'Grant Tester Test Coins',
                  body:
                      'Give a tester non-cash Test Coins for gifts, levels, badges and battle QA. Test Coins can never create real creator earnings.',
                  label: 'Grant',
                  onTap: _busy
                      ? null
                      : () => _OwnerControlDialogs(this).grantTesterCoins(),
                ),
                const SizedBox(height: 10),
                _Action(
                  key: const Key('owner-open-paypal-funding'),
                  icon: Icons.paypal_outlined,
                  title: 'Open PayPal Business',
                  body:
                      'View the real cash available in your PayPal Business account. PayPal may not show an Add Money option on every account, so Fameverse does not assume that button exists.',
                  label: 'Open PayPal',
                  onTap: _openPayPal,
                ),
                const SizedBox(height: 10),
                _Action(
                  key: const Key('owner-record-settled-reserve'),
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Record Reward Funds',
                  body:
                      'Record only real business cash you have already set aside for rewards. Example: record \$10 and Fameverse shows \$10 available in the Reward Reserve. This does not move money.',
                  label: 'Record funds',
                  onTap: _busy ? null : _recordSettledReserve,
                ),
                const SizedBox(height: 10),
                _Action(
                  key: const Key('owner-issue-cash-reward-coins'),
                  icon: Icons.toll_rounded,
                  title: 'Create Cash-Backed Fame Coins',
                  body:
                      'Create coins from the Reward Reserve only when you want those coins to be capable of creating real creator earnings. Promo Fame Coins stay separate.',
                  label: 'Create',
                  onTap: _busy ? null : _issueCashRewardCoins,
                ),
                const SizedBox(height: 10),
                _Action(
                  key: const Key('owner-open-paypal-withdrawal'),
                  icon: Icons.account_balance_rounded,
                  title: 'Transfer owner earnings to bank',
                  body:
                      'Fameverse does not pretend to move PayPal funds. Open PayPal and transfer only settled business cash that is not needed for creator/user liabilities.',
                  label: 'Open PayPal',
                  onTap: _openPayPal,
                ),
                const SizedBox(height: 12),
                const _Notice(
                  icon: Icons.info_outline_rounded,
                  title: 'Provider balance is separate',
                  body:
                      'Platform share earned is an internal Fameverse ledger number, not your live PayPal balance. Provider fees, taxes, refunds, disputes and store settlement can reduce real cash available.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
