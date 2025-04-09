#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

namespace Ui
{
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget* parent = 0);
    ~MainWindow();

private slots:
    void slot_actionQuit_triggered();

    void slot_actionCamera_Controls_triggered();

    void slot_actionLoad_Environment_Map_Ctrl_O_triggered();

    void slot_actionLoad_JSON_Scene_triggered();

private:
    Ui::MainWindow* ui;
};

#endif  // MAINWINDOW_H
