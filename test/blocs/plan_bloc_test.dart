import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otpand/blocs/plan/bloc.dart';
import 'package:otpand/blocs/plan/events.dart';
import 'package:otpand/blocs/plan/repository.dart';
import 'package:otpand/blocs/plan/states.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/objects/plan.dart';

import '../helpers/test_factories.dart';

class MockPlanRepository extends Mock implements PlanRepository {}

void main() {
  late MockPlanRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(<Leg>[]);
  });

  setUp(() {
    mockRepo = MockPlanRepository();
  });

  Plan makePlanWithRealTime({bool realTime = false}) {
    return makePlan(legs: [makeLeg(id: 'leg-1', realTime: realTime)]);
  }

  group('PlanBloc', () {
    test('initial state is PlanInitial', () {
      final bloc = PlanBloc(mockRepo);
      expect(bloc.state, isA<PlanInitial>());
      bloc.close();
    });

    group('LoadPlan', () {
      blocTest<PlanBloc, PlanState>(
        'emits PlanLoaded with plan when plan has no real-time legs',
        build: () => PlanBloc(mockRepo),
        act: (bloc) => bloc.add(LoadPlan(makePlanWithRealTime(realTime: false))),
        expect: () => [
          isA<PlanLoaded>()
              .having((s) => s.autoUpdateEnabled, 'autoUpdateEnabled', false)
              .having((s) => s.updating, 'updating', false),
        ],
      );

      blocTest<PlanBloc, PlanState>(
        'emits PlanLoaded with autoUpdateEnabled=true when plan has real-time legs',
        build: () => PlanBloc(mockRepo),
        act: (bloc) => bloc.add(LoadPlan(makePlanWithRealTime(realTime: true))),
        expect: () => [
          isA<PlanLoaded>().having(
            (s) => s.autoUpdateEnabled,
            'autoUpdateEnabled',
            true,
          ),
        ],
      );

      blocTest<PlanBloc, PlanState>(
        'loaded state contains the provided plan',
        build: () => PlanBloc(mockRepo),
        act: (bloc) {
          final plan = makePlan(fromName: 'TestOrigin');
          bloc.add(LoadPlan(plan));
        },
        expect: () => [
          isA<PlanLoaded>().having(
            (s) => s.plan.fromName,
            'plan.fromName',
            'TestOrigin',
          ),
        ],
      );
    });

    group('UpdateLegs', () {
      blocTest<PlanBloc, PlanState>(
        'does nothing when state is not PlanLoaded',
        build: () => PlanBloc(mockRepo),
        act: (bloc) => bloc.add(const UpdateLegs()),
        expect: () => <PlanState>[],
      );

      blocTest<PlanBloc, PlanState>(
        'emits PlanLoaded with updated legs on success',
        build: () => PlanBloc(mockRepo),
        setUp: () {
          final updatedLegs = [makeLeg(id: 'leg-1', distance: 9999)];
          when(() => mockRepo.updateLegs(any()))
              .thenAnswer((_) async => updatedLegs);
        },
        seed: () => PlanLoaded(plan: makePlanWithRealTime()),
        act: (bloc) => bloc.add(const UpdateLegs()),
        expect: () => [
          isA<PlanLoaded>().having((s) => s.updating, 'updating', true),
          isA<PlanLoaded>()
              .having((s) => s.updating, 'updating', false)
              .having(
                (s) => s.plan.legs.first.distance,
                'updated distance',
                9999,
              ),
        ],
      );

      blocTest<PlanBloc, PlanState>(
        'emits PlanError when updateLegs throws',
        build: () => PlanBloc(mockRepo),
        setUp: () {
          when(() => mockRepo.updateLegs(any()))
              .thenThrow(Exception('Network error'));
        },
        seed: () => PlanLoaded(plan: makePlanWithRealTime()),
        act: (bloc) => bloc.add(const UpdateLegs()),
        expect: () => [
          isA<PlanLoaded>().having((s) => s.updating, 'updating', true),
          isA<PlanError>().having(
            (s) => s.message,
            'message',
            contains('Network error'),
          ),
        ],
      );
    });

    group('ToggleAutoUpdate', () {
      blocTest<PlanBloc, PlanState>(
        'does nothing when state is not PlanLoaded',
        build: () => PlanBloc(mockRepo),
        act: (bloc) => bloc.add(const ToggleAutoUpdate()),
        expect: () => <PlanState>[],
      );

      blocTest<PlanBloc, PlanState>(
        'toggles autoUpdateEnabled from false to true',
        build: () => PlanBloc(mockRepo),
        seed: () => PlanLoaded(
          plan: makePlanWithRealTime(),
          autoUpdateEnabled: false,
        ),
        act: (bloc) => bloc.add(const ToggleAutoUpdate()),
        expect: () => [
          isA<PlanLoaded>().having(
            (s) => s.autoUpdateEnabled,
            'autoUpdateEnabled',
            true,
          ),
        ],
      );

      blocTest<PlanBloc, PlanState>(
        'toggles autoUpdateEnabled from true to false',
        build: () => PlanBloc(mockRepo),
        seed: () => PlanLoaded(
          plan: makePlanWithRealTime(),
          autoUpdateEnabled: true,
        ),
        act: (bloc) => bloc.add(const ToggleAutoUpdate()),
        expect: () => [
          isA<PlanLoaded>().having(
            (s) => s.autoUpdateEnabled,
            'autoUpdateEnabled',
            false,
          ),
        ],
      );
    });

    group('PlanLoaded.copyWith', () {
      test('updating flag can be toggled', () {
        final state = PlanLoaded(plan: makePlan(), updating: false);
        final updated = state.copyWith(updating: true);
        expect(updated.updating, isTrue);
        expect(updated.plan, state.plan);
      });

      test('plan can be replaced', () {
        final state = PlanLoaded(plan: makePlan(fromName: 'Old'));
        final newPlan = makePlan(fromName: 'New');
        final updated = state.copyWith(plan: newPlan);
        expect(updated.plan.fromName, 'New');
      });
    });
  });
}
