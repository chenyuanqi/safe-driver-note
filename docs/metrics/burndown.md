# 迭代燃尽图模板（Burndown）

> 用于追踪 Sprint 剩余工作量（Story Points）。支持 Markdown/CSV 维护，或使用在线表格。

## 使用说明
1. 在 Sprint 规划时记录总点数（Total SP）。
2. 每日更新“剩余点数（Remaining SP）”。
3. 与理想燃尽线对比，识别偏差并采取措施。

## 表格模板（Markdown）
| Day | Remaining SP | Note |
|---|---:|---|
| 1 | 40 | 规划完成 |
| 2 | 36 | 需求澄清完成 |
| 3 | 32 | 组件开发进行中 |
| 4 | 28 | 集成通过 |
| 5 | 24 | … |
| 6 | 20 | … |
| 7 | 16 | … |
| 8 | 12 | … |
| 9 | 8 | … |
| 10 | 0 | 评审/回顾 |

> 可将本表复制为每个 Sprint 的独立文件：`burndown-sprint-YYYYMMDD.md`

## CSV 模板
```
Day,RemainingSP,Note
1,40,规划完成
2,36,需求澄清完成
3,32,组件开发进行中
4,28,集成通过
5,24,
6,20,
7,16,
8,12,
9,8,
10,0,评审/回顾
```

## Mermaid 可视化（可选）
> 若平台支持 Mermaid，可用下述示例绘制折线图。

```mermaid
xychart-beta
    title "Sprint 燃尽图示例"
    x-axis [1,2,3,4,5,6,7,8,9,10]
    y-axis "SP" 0 --> 40
    line "Remaining" [40,36,32,28,24,20,16,12,8,0]
    line "Ideal" [40,36,32,28,24,20,16,12,8,0]
```
