import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/aby_colors.dart';
import '../../../theme/aby_mark.dart';
import '../../../theme/aby_theme.dart';
import '../../../widgets/option_chip.dart';
import '../../../widgets/pin_pad.dart';
import '../controllers/sign_in_controller.dart';

class SignInView extends GetView<SignInController> {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final selected = controller.selected.value;
          final people = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const AbyMark(size: 40),
                const SizedBox(width: AbySpace.s3),
                Flexible(
                  child: Text(controller.shopName,
                      style: AbyText.title.copyWith(color: c.ink)),
                ),
              ]),
              const SizedBox(height: AbySpace.s6),
              Text("Who's on the till?", style: AbyText.heading.copyWith(color: c.ink)),
              const SizedBox(height: AbySpace.s3),
              Wrap(
                spacing: AbySpace.s2,
                runSpacing: AbySpace.s2,
                children: [
                  for (final person in controller.staff)
                    OptionChip(
                      label: person.name,
                      trailing: person.role.label,
                      selected: selected == person,
                      onTap: () => controller.select(person),
                    ),
                ],
              ),
            ],
          );
          final pad = selected == null
              ? Text('Pick your name.', style: AbyText.body.copyWith(color: c.inkMuted))
              : PinPad(
                  // A new pad (cleared digits) for each person.
                  key: ValueKey(selected.id),
                  title: 'PIN for ${selected.name}',
                  onSubmit: controller.submitPin,
                );
          return LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AbySpace.s6),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AbySpace.s6 * 2),
                child: wide
                    ? Row(
                        children: [
                          Expanded(child: people),
                          const SizedBox(width: AbySpace.s8),
                          Expanded(child: Center(child: pad)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          people,
                          const SizedBox(height: AbySpace.s6),
                          Center(child: pad),
                        ],
                      ),
              ),
            );
          });
        }),
      ),
    );
  }
}
