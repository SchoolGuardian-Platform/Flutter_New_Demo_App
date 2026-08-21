import { Request, Response, NextFunction } from "express";
import { WellbeingService } from "../service/wellbeing.service";
import { UploadUsageInput, UpdateLimitInput } from "../validators/wellbeing.validator";

export async function uploadUsageController(req: Request<{}, {}, UploadUsageInput>, res: Response, next: NextFunction): Promise<void> {
  try {
    const studentId = req.user!.id;
    const result = await WellbeingService.uploadUsage(studentId, req.body);
    res.status(200).json({ data: result });
  } catch (error) {
    next(error);
  }
}

export async function getWellbeingMeController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const studentId = req.user!.id;
    const result = await WellbeingService.getWellbeingMe(studentId);
    if (!result) {
      res.status(404).json({ message: "No wellbeing data found for your account." });
      return;
    }
    res.status(200).json({ data: result });
  } catch (error) {
    next(error);
  }
}

export async function getWellbeingDailyController(req: Request<{ studentId: string }>, res: Response, next: NextFunction): Promise<void> {
  try {
    const requestedDate = req.query.date as string | undefined;
    const result = await WellbeingService.getWellbeingDaily(req.params.studentId, req.user!, requestedDate);
    if (!result) {
      res.status(404).json({ message: "No wellbeing data found for the specified date." });
      return;
    }
    res.status(200).json({ data: result });
  } catch (error) {
    next(error);
  }
}

export async function getWellbeingWeeklyController(req: Request<{ studentId: string }>, res: Response, next: NextFunction): Promise<void> {
  try {
    const startDate = req.query.startDate as string | undefined;
    const endDate = req.query.endDate as string | undefined;
    const result = await WellbeingService.getWellbeingWeekly(req.params.studentId, req.user!, startDate, endDate);
    if (!result) {
      res.status(404).json({ message: "No wellbeing data found for the specified period." });
      return;
    }
    res.status(200).json({ data: result });
  } catch (error) {
    next(error);
  }
}

export async function updateLimitController(req: Request<{ studentId: string }, {}, UpdateLimitInput>, res: Response, next: NextFunction): Promise<void> {
  try {
    const parentId = req.user!.id;
    const result = await WellbeingService.updateLimit(req.params.studentId, parentId, req.body);
    res.status(200).json({ data: result });
  } catch (error) {
    next(error);
  }
}

export async function getLimitController(req: Request<{ studentId: string }>, res: Response, next: NextFunction): Promise<void> {
  try {
    const result = await WellbeingService.getLimit(req.params.studentId, req.user!);
    if (!result) {
      res.status(404).json({ message: "No wellbeing limit configured for this student." });
      return;
    }
    res.status(200).json({ data: result });
  } catch (error) {
    next(error);
  }
}
