import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:animation_list/animation_list.dart';
import 'package:flexiphones/shared_widgets/quick_pay.dart';
import 'package:flexiphones/helpers/app_update.dart';
import 'package:flexiphones/helpers/push_service.dart';
import 'package:flexiphones/extensions/ui_values.dart';
import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/models/notifications_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_home_shell.dart';
import 'package:flexiphones/screens/browse/browse.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/search.dart';
import 'package:flexiphones/screens/cart/cart.dart';
import 'package:flexiphones/screens/home/home.dart';
import 'package:flexiphones/screens/layout/components/bottom_nav.dart';
import 'package:flexiphones/screens/onboarding/email_phone/email_signin.dart';
import 'package:flexiphones/screens/onboarding/init_ob/stepsPage.dart';
import 'package:flexiphones/screens/orders/orders.dart';
import 'package:flexiphones/screens/orders/sub_pages/order_details.dart';
import 'package:flexiphones/screens/orders/sub_pages/pay_now.dart';
import 'package:flexiphones/screens/orders/sub_pages/plan_completed.dart';
import 'package:flexiphones/screens/profile/sub_pages/repayment_calendar.dart';
import 'package:flexiphones/screens/profile/profile.dart';
import 'package:flexiphones/screens/reviews/reviews.dart' show MyReviewsScreen;
import 'package:flexiphones/shared_widgets/confirmation_dialogue.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/neu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initScreen = 0});
  final int initScreen;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final List<Map> _pages = [
    {0: "FlexiPhones ", 1: Home()},
    {0: "Browse", 1: Browse()},
    {0: "Cart", 1: ShoppingCartScreen()},
    {0: "Orders", 1: Orders()},
    {0: "Profile", 1: Profile()},
  ];
  final List<Map> _pages2 = [
    {0: "FlexiPhones ", 1: Home()},
    {0: "Browse", 1: Browse()},
    {0: "Cart", 1: ShoppingCartScreen()},
  ];
  SharedProvider? shdP;

  int _selectedIndex = 0;

  Timer? tm;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Order status can change while the app is in the background (e.g. a
    // down payment approved on the phone), so reload orders on return.
    if (state == AppLifecycleState.resumed && shdP?.userData != null) {
      shdP!.getOrders(refresh: true, next: false).catchError((_) {});
      shdP!.pollNotifications();
      shdP!.getOrdersStanding();
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _onTabTapped(widget.initScreen);
      // Notification channel + permission, then Firebase push (Android).
      await shdP!.initializeNotifications();
      await PushService.init();
      await PushService.setRoles(
        customer: shdP!.userData != null,
        agent: shdP!.partnerData != null,
      );
      if (shdP!.userData != null) {
        if (!mounted) return;
        await shdP!.checkINIT(context);
        if (shdP!.orders.isEmpty) {
          shdP!.getOrders(refresh: true, next: false).catchError((_) {});
        }
        shdP!.getOrdersStanding();
        // Cheap unread-count poll; the list reloads only when it changes.
        tm = Timer.periodic(Duration(seconds: 15), (timer) {
          if (shdP != null) {
            shdP!.pollNotifications();
          }
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tm?.cancel();
    super.dispose();
  }

  /// Each tab's page colour, so the top bar blends into it.
  Color _pageBg(BuildContext context, ColorScheme ch, SharedProvider p) {
    if (p.search) return ch.surface;
    if (_selectedIndex == 0) return Neu.bg(context);
    if (_selectedIndex == 2 || _selectedIndex == 3) {
      return const Color(0xFFF2F4F7);
    }
    return ch.surface;
  }
  // Define the key globally
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);
    shdP = sharedProvider;
    // Signed out while on Orders/Profile (guests only have 3 tabs): go Home.
    if (sharedProvider.userData == null && _selectedIndex >= _pages2.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    }
    var ch = Theme.of(context).colorScheme;
    var pageTitle = Padding(
      padding: const EdgeInsets.all(10.0),
      child: Text(
        sharedProvider.search
            ? "Search"
            : (sharedProvider.userData == null
                    ? _pages2[_selectedIndex.clamp(0, _pages2.length - 1)][0]
                    : _pages[_selectedIndex][0])
                as String,
        style: ptstyle(
          size: 17,
          weight: 700,
          color: ch.onSurface,
        ),
      ),
    );
    var searchButton = AbsorbPointer(
      absorbing: sharedProvider.userData == null,
      child: Opacity(
        opacity: sharedProvider.userData == null ? 0.3 : 1.0,
        child: IconButton.filledTonal(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(ch.surfaceContainerLow),
          ),
          onPressed: () {
            sharedProvider.getFilteredProducts();
            sharedProvider.enableSearching();
          },
          icon: Icon(Icons.search),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: UpgradeAlert(
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: _pageBg(context, ch, sharedProvider),
          drawer: NotificationDrawer(),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            // Plain, quiet bar like iOS: the page content carries the look.
            child: AppBar(
              automaticallyImplyLeading: false,
              excludeHeaderSemantics: true,
              backgroundColor: _pageBg(context, ch, sharedProvider),
              elevation: 0,
              scrolledUnderElevation: 0,

              toolbarHeight: 0,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(55),
                child: Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Center(child: pageTitle),

                      if (!sharedProvider.search)
                        Container(
                          height: 50,
                          padding: const EdgeInsets.only(right: 10.0),
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 400),

                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Home has its own search pill.
                                if (_selectedIndex == 1 &&
                                    !sharedProvider.search)
                                  searchButton,

                                AbsorbPointer(
                                  absorbing: sharedProvider.userData == null,
                                  child: Opacity(
                                    opacity:
                                        sharedProvider.userData == null
                                            ? 0.3
                                            : 1.0,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 5.0,
                                        left: 5,
                                      ),
                                      child: Badge(
                                        alignment: Alignment.topRight,
                                        label: Text(
                                          sharedProvider.unreadBadge > 9
                                              ? "9+"
                                              : sharedProvider.unreadBadge
                                                  .toString(),
                                          style: ptstyle(size: 12, weight: 200),
                                        ),
                                        isLabelVisible:
                                            sharedProvider.unreadBadge > 0,
                                        child: SizedBox(
                                          height: 40,
                                          child: IconButton.filledTonal(
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  WidgetStatePropertyAll(
                                                    ch.surfaceContainerLow,
                                                  ),
                                            ),
                                            onPressed: () async {
                                              scaffoldKey.currentState!
                                                  .openDrawer();
                                            },
                                            icon: Icon(
                                              Icons
                                                  .notifications_active_outlined,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_selectedIndex == 4)
                                  IconButton.filledTonal(
                                    onPressed:
                                        () => sharedProvider.enDM(context),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(
                                        ch.surfaceContainerLow,
                                      ),
                                    ),
                                    icon: Icon(
                                      !sharedProvider.thmMode
                                          ? Icons.sunny
                                          : Icons.dark_mode_rounded,
                                    ),
                                  ),

                                SizedBox(
                                  height: 40,
                                  child: IconButton.filledTonal(
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(
                                        ch.surfaceContainerLow,
                                      ),
                                    ),
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) {
                                          return StepsPage();
                                        },
                                      );
                                    },
                                    icon: Icon(
                                      Icons.info_outline_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                if (_selectedIndex == 1)
                                  AbsorbPointer(
                                    absorbing: !sharedProvider.adSeenThisWeek,
                                    child: Opacity(
                                      opacity:
                                          !sharedProvider.adSeenThisWeek
                                              ? 0.3
                                              : 1.0,
                                      child: SizedBox(
                                        height: 40,
                                        child: IconButton.filledTonal(
                                          style: IconButton.styleFrom(
                                            backgroundColor: ch.primaryFixed
                                                .withOpacity(0.5),
                                          ),
                                          onPressed: () async {
                                            sharedProvider.markAdAsNotShown();
                                          },
                                          icon: Icon(
                                            Icons.sell_outlined,
                                            size: 20,
                                            color: ch.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: WillPopScope(
            onWillPop: () async {
              await showConfirmationDialog(
                title: "Exit App",
                content: "Are you sure you want to exit the app?",
                confirmText: "Yes, Exit",
                cancelText: "No, Stay",
                confirm: () {
                  SystemNavigator.pop();
                },
                context: context,
              );

              return false;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child:
                    sharedProvider.search
                        ? SearchP()
                        : sharedProvider.userData == null
                        ? _pages2[_selectedIndex.clamp(0, _pages2.length - 1)][1]
                        : _pages[_selectedIndex][1],
              ),
            ),
          ),
          // Always-there "Pay today" / "Catch up" for anyone on a plan
          // (Home, Browse and Orders; the bag has its own checkout button).
          floatingActionButton:
              sharedProvider.userData != null &&
                      !sharedProvider.search &&
                      const [0, 1, 3].contains(_selectedIndex)
                  ? const QuickPayButton()
                  : null,
          // One slim tab bar for everyone. Guests get "Sign in"; anyone
          // with an agent account gets "Agent" to go back to it.
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex:
                sharedProvider.userData != null
                    ? _selectedIndex
                    : _selectedIndex.clamp(0, _pages2.length - 1),
            onTap: (p0) {
              _onTabTapped(p0);
              sharedProvider.enableSearching(change: false);
            },
            cartItems: sharedProvider.cartItems,
            ofl: sharedProvider.userData == null,
            showAgentTab: sharedProvider.isAgentAccount,
            onAgentTap: () => NavigationHelper.push(context, AgentHomeShell()),
            onSignIn: () => NavigationHelper.push(context, EmailSignin()),
          ),
        ),
      ),
    );
  }
}

class NotificationDrawer extends StatelessWidget {
  const NotificationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);
    var ch = Theme.of(context).colorScheme;
    var length2 = sharedProvider.notifications.length;
    return Container(
      padding: EdgeInsets.only(top: 50),
      width: 80.w,
      decoration: BoxDecoration(color: ch.surface),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Column(
            children: [
              Text(
                "Notifications",
                style: ptstyle(
                  size: 20,
                  weight: 400,
                  color: ch.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 70,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ch.primaryFixed.withOpacity(0.3),

                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            length2.toString().toHumanReadable(),
                            style: ptstyle(
                              size: 15,
                              weight: 600,
                              color: ch.onSurfaceVariant.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            "All",
                            style: ptstyle(
                              size: 12,
                              weight: 600,
                              color: ch.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 70,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ch.primaryFixed.withOpacity(0.3),

                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            sharedProvider.readNTF.length
                                .toString()
                                .toHumanReadable(),
                            style: ptstyle(
                              size: 15,
                              weight: 600,
                              color: ch.onSurfaceVariant.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            "Read",
                            style: ptstyle(
                              size: 12,
                              weight: 600,
                              color: ch.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 70,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ch.primaryFixed.withOpacity(0.3),

                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            sharedProvider.unreadBadge
                                .toString()
                                .toHumanReadable(),
                            style: ptstyle(
                              size: 15,
                              weight: 600,
                              color: ch.onSurfaceVariant.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            "Unread",
                            style: ptstyle(
                              size: 12,
                              weight: 600,
                              color: ch.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: AnimationList(
                  animationDirection: AnimationDirection.vertical,
                  duration: 300,
                  reBounceDepth: 0,
                  padding: EdgeInsets.only(bottom: 100, top: 10),
                  children: [
                    if (length2 == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 54,
                              color: ch.onSurfaceVariant.withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "You're all caught up.",
                              style: ptstyle(
                                size: 16,
                                weight: 700,
                                color: ch.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "New notifications will show up here.",
                              style: ptstyle(
                                size: 12.5,
                                weight: 400,
                                color: ch.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ...List.generate(length2, (index) {
                      var data = sharedProvider.notifications[index];

                      return NTFCnt(ch: ch, data: data);
                    }),
                    // Older notifications are on later pages (10 per page).
                    if (sharedProvider.notificationsHasMore)
                      Center(
                        child: TextButton(
                          onPressed:
                              sharedProvider.loadingMoreNotifications
                                  ? null
                                  : sharedProvider.loadMoreNotifications,
                          child: Text(
                            sharedProvider.loadingMoreNotifications
                                ? "Loading..."
                                : "Load older notifications",
                            style: ptstyle(size: 12, weight: 600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton.filledTonal(
              style: IconButton.styleFrom(backgroundColor: ch.primaryFixed),
              onPressed:
                  () =>
                      sharedProvider.readAlLoad
                          ? null
                          : sharedProvider.readAllNotification(),
              icon:
                  sharedProvider.readAlLoad
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                      : Icon(
                        sharedProvider.unreadNTF.isEmpty
                            ? Icons.refresh_rounded
                            : Icons.mark_email_read_outlined,
                        color:
                            AdaptiveTheme.of(context).mode.isDark
                                ? ch.onSurface
                                : ch.onSurfaceVariant,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class NTFCnt extends StatefulWidget {
  const NTFCnt({super.key, required this.ch, required this.data});

  final ColorScheme ch;
  final NotificationData data;

  @override
  State<NTFCnt> createState() => _NTFCntState();
}

class _NTFCntState extends State<NTFCnt> {
  bool more = false;

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);
    final content = widget.data.data;
    read() {
      if (widget.data.isUnread) {
        sharedProvider.readNotification(widget.data.id);
      }
      setState(() {
        more = !more;
      });
    }

    // Where a tap goes depends on `kind` (see the backend notification table).
    final orderId = content.orderId;
    open() {
      if (content.isAppUpdate) {
        if (widget.data.isUnread) {
          sharedProvider.readNotification(widget.data.id);
        }
        AppUpdate.openStore(content.androidUrl);
        return;
      }
      if (content.isReviewReply) {
        if (widget.data.isUnread) {
          sharedProvider.readNotification(widget.data.id);
        }
        NavigationHelper.push(
          context,
          MyReviewsScreen(highlightId: content.reviewId),
        );
        return;
      }
      if (orderId == null) return read();
      if (widget.data.isUnread) {
        sharedProvider.readNotification(widget.data.id);
      }
      if (content.isRepaymentReminder || content.isDeviceLocked) {
        NavigationHelper.push(context, PayNowScreen(orderId: orderId));
      } else if (content.isPlanCompleted) {
        sharedProvider.getOrders(refresh: true, next: false);
        NavigationHelper.push(context, const PlanCompletedScreen());
      } else if (content.isPaymentCompleted) {
        sharedProvider.getRepaymentCL(refresh: true, next: false);
        NavigationHelper.push(context, RepaymentCalendar());
      } else {
        sharedProvider.getOrder(orderId);
        NavigationHelper.push(context, OrderDetailsWidget());
      }
    }

    // Reminders: due_* amber, missed_* red; payments green.
    final stage = content.reminderStage ?? "";
    final Color? accent =
        content.isDeviceLocked
            ? Colors.red
            : content.isRepaymentReminder
            ? (stage.startsWith("missed") ? Colors.red : Colors.orange.shade800)
            : content.isPaymentCompleted ||
                content.isDownPayment ||
                content.isPlanCompleted
            ? Colors.green
            : null;
    final IconData icon =
        content.isDeviceLocked
            ? Icons.lock_rounded
            : content.isPlanCompleted
            ? Icons.celebration_rounded
            : content.isRepaymentReminder
            ? (stage.startsWith("missed")
                ? Icons.warning_amber_rounded
                : Icons.schedule_rounded)
            : content.isPaymentCompleted || content.isDownPayment
            ? Icons.check_circle_outline
            : content.isAccountNotice
            ? Icons.verified_user_outlined
            : content.isAppUpdate
            ? Icons.system_update_rounded
            : content.isReviewReply
            ? Icons.reviews_outlined
            : Icons.notification_important_outlined;

    return InkWell(
      radius: 10,
      onTap: () => open(),
      child: Container(
        margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              accent?.withOpacity(0.08) ??
              widget.ch.primaryFixed.withOpacity(0.3),
          border:
              accent == null
                  ? null
                  : Border.all(color: accent.withOpacity(0.45)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Icon(
                icon,
                size: 15,
                color: accent ?? widget.ch.onSurface.withOpacity(0.3),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.data.data.title,
                          style: ptstyle(
                            size: 12,
                            weight: 600,
                            color: widget.ch.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),

                      if (widget.data.isUnread)
                        Icon(
                          Icons.circle,
                          size: 10.0,
                          color: widget.ch.primary,
                        ),
                    ],
                  ),
                  Text(
                    widget.data.data.message,
                    maxLines: more ? null : 1,
                    overflow: more ? null : TextOverflow.ellipsis,
                    style: ptstyle(
                      size: 12,
                      weight: 400,
                      color: widget.ch.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.data.isUnread
                              ? "...${DateTime.parse(widget.data.createdAt).toAgo()}"
                              : DateTime.parse(
                                widget.data.createdAt,
                              ).formatDate(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ptstyle(
                            size: 12,
                            weight: 400,
                            color: widget.ch.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 25,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                          ),
                          onPressed: () => read(),
                          child: Text(
                            more
                                ? "collapse"
                                : (widget.data.isUnread
                                    ? "Read"
                                    : "Expand"),
                            style: ptstyle(size: 11, weight: 600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}